

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'FLOWMATIC/LEXER'
# log                       = CND.get_logger 'plain',     badge
# info                      = CND.get_logger 'info',      badge
# whisper                   = CND.get_logger 'whisper',   badge
# alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
# warn                      = CND.get_logger 'warn',      badge
# help                      = CND.get_logger 'help',      badge
# urge                      = CND.get_logger 'urge',      badge
# echo                      = CND.echo.bind CND
PS                        = require 'pipestreams'
{ $, map, }               = PS
CS                        = require 'coffeescript'
FLOWMATIC                 = require '..'


{ default: lex, SourceType, } = require 'stupid-coffee-lexer'


#-----------------------------------------------------------------------------------------------------------
@$coffee_lex = ->
  return $ ( source, send ) =>
    ( lex source ).forEach ( token ) =>
      type                  = SourceType[ token.type ].toLowerCase()
      { start, end: stop }  = token
      image                 = source[ start ... stop ]
      send { start, stop, type, image, }
      # send { start, stop, type, image, source, }
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@$add_isid = ->
  return map ( token ) =>
    token.isxid = FLOWMATIC.U.is_xidentifier token.image
    return token

#-----------------------------------------------------------------------------------------------------------
@$rewrite_whitespace = ->
  return map ( token ) =>
    { start, stop, type, image, } = token
    #.......................................................................................................
    switch type
      when 'space'
        if /^\x20+$/.test image
          token.count   = stop - start
          token.type    = 'lws'
      when 'newline'
        token.count   = 1
        token.type    = 'nl'
    #.......................................................................................................
    # token.specifier = "#{token.type}/#{token.image}"
    return token

#-----------------------------------------------------------------------------------------------------------
@$collapse_newlines = ->
  ### TAINT does not collapse non-empty blank lines ###
  send      = null
  nl_count  = 0
  nl_start  = null
  #.........................................................................................................
  flush = ->
    if nl_count > 0
      image = '\n'.repeat nl_count
      stop  = nl_start + nl_count
      send { start: nl_start, stop, type: 'nl', image, count: nl_count, }
      nl_count = 0
      nl_start = null
    return null
  #.........................................................................................................
  return $ 'null', ( token, send_ ) =>
    send = send_
    if token?
      { type, start, } = token
      if type is 'nl'
        nl_start ?= start
        nl_count += 1
      else
        flush()
        send token
    else
      flush()
    return null

#-----------------------------------------------------------------------------------------------------------
@$add_blank = ->
  return map ( token ) =>
    { type, } = token
    token.blank = type in [ 'lws', 'nl', 'space', ]
    return token

#-----------------------------------------------------------------------------------------------------------
@$add_start_stop = ->
  is_first  = yes
  stop      = 0
  return $ 'null', ( token, send ) =>
    if is_first
      is_first = no
      send { start: 0, stop: 0, type: 'start', blank: yes, image: '', }
    if token?
      { stop, } = token
      send token
    else
      send { start: stop, stop, type: 'stop', blank: yes, image: '', }
    return null

#-----------------------------------------------------------------------------------------------------------
@$add_indentation = ->
  ### TAINT should deal with tab characters, uneven number of spaces ###
  return PS.$gliding_window 2, ( section ) =>
    [ t0, t1, ] = section
    if t0.blank and t1.type is 'lws'
      t1.type   = 'indentation'
      t1.level  = Math.floor t1.image.length / 2
    return null

#-----------------------------------------------------------------------------------------------------------
@$add_indent = ->
  prv_level = 0
  return PS.$gliding_window 1, ( section ) =>
    [ { start, type, level, }, ] = section
    is_indent = type is 'indentation' and level > prv_level
    if is_indent
      start             = start
      stop              = start
      blank             = no
      isxid             = no
      while prv_level < level
        prv_level  += +1
        my_level    = level + ( level - prv_level ) - 1
        image       = ''
        type        = 'indent'
        new_token   = { start, stop, type, image, level: my_level, blank, isxid, }
        section.unshift new_token
    prv_level = level if level?
    return null

#-----------------------------------------------------------------------------------------------------------
@$add_dedent = ->
  prv_level = 0
  return PS.$gliding_window 2, ( section ) =>
    [ t0, t1, ]                                       = section
    { start: start_0, type: type_0, level: level_0, } = t0
    { start: start_1, type: type_1, level: level_1, } = t1
    level                                             = null
    if type_0 is 'nl'
      if type_1 is 'indentation'
        level = level_1
      else
        level = 0
    is_dedent = level? and ( level < prv_level ) and ( type_1 isnt 'indent' )
    if is_dedent
      start             = start_0
      stop              = start
      blank             = no
      isxid             = no
      while prv_level > level
        prv_level  += -1
        my_level    = level + ( level - prv_level ) + 1
        image       = ''
        type        = 'dedent'
        new_token   = { start, stop, type, image, level: my_level, blank, isxid, }
        section.unshift new_token
    prv_level = if level? then level else ( if level_1? then level_1 else prv_level )
    return null

#-----------------------------------------------------------------------------------------------------------
@$add_eofdedent = ->
  prv_level = 0
  return PS.$gliding_window 2, ( section ) =>
    [ t0, t1, ]                                       = section
    { start: start_0, type: type_0, level: level_0, } = t0
    { start: start_1, type: type_1, level: level_1, } = t1
    is_eofdedent = type_1 is 'stop' and prv_level > 0
    # debug '77728', ( rpr @_image_from_section section ), type_1, prv_level
    if is_eofdedent
      start             = start_1
      stop              = start
      blank             = no
      isxid             = no
      level             = level_1
      image             = ''
      type              = 'dedent'
      level             = prv_level
      section.pop()
      while level > 0
        level    += -1
        new_token = { start, stop, type, image, level, blank, isxid, }
        section.push new_token
      section.push t1
    prv_level = level_1 if level_1?
    return null

#-----------------------------------------------------------------------------------------------------------
@$lex = ->
  pipeline = []
  pipeline.push @$coffee_lex()
  pipeline.push @$add_isid()
  pipeline.push @$rewrite_whitespace()
  pipeline.push @$collapse_newlines()
  pipeline.push @$add_blank()
  pipeline.push @$add_start_stop()
  pipeline.push @$add_indentation()
  pipeline.push @$add_indent()
  pipeline.push @$add_dedent()
  pipeline.push @$add_eofdedent()
  return PS.pull pipeline...




