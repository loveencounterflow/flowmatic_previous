
############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'FLOWMATIC/PROTOCOL'
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

#-----------------------------------------------------------------------------------------------------------
@$transpile_to_cs_tokens = ->
  pipeline = []
  # pipeline.push PS.$show()
  pipeline.push @_$translate_slashdot()
  pipeline.push @_$translate_dashed_identifier()
  return PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@$cs_tokens_as_text = ->
  pipeline = []
  # pipeline.push PS.$show()
  pipeline.push map ( token ) ->
    { image, cs, } = token
    return cs ? image
  pipeline.push PS.$join()
  return PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@$cs_text_as_js = ->
  return map ( cs_text ) -> CS.compile cs_text

#-----------------------------------------------------------------------------------------------------------
@$cs_tokens_as_protocol_A = ->
  collector = []
  return $ 'null', ( token, send ) ->
    if token?
      { start, stop, type, image, } = token
      collector.push "#{start}:#{stop},#{type},#{rpr image}"
    else
      send collector.join '\n'
    return null

#-----------------------------------------------------------------------------------------------------------
@$cs_tokens_as_protocol_B = ->
  collector = []
  line      = []
  level     = 0
  return $ 'null', ( token, send ) ->
    if token?
      { type, image, } = token
      switch type
        when 'stop'
          collector.push line.join ' ' if line.length > 0
          line.length = 0
        when 'nl'
          collector.push line.join ' '
          line.length = 0
        when 'indent'
          line.push '>'
        when 'dedent'
          line.push '<'
        when 'indentation', 'start'
          null
        else
          line.push "(#{type}|#{rpr image})"
    else
      send collector.join '\n'
    return null

#-----------------------------------------------------------------------------------------------------------
@$show = ->
  return map ( token ) ->
    { start
      stop
      type
      image
      isxid
      cs
      level } = token
    #.......................................................................................................
    start     = rpr start; start   = ' ' + start while start.length < 3
    stop      = rpr stop ; stop    = ' ' + stop  while  stop.length < 3
    padding   = ' '.repeat 20 - type.length
    cs_txt    = ''
    level_txt = ''
    #.......................................................................................................
    switch
      when type in [ 'indent', 'dedent', ]
        color = CND.steel
      when type in [ 'lws', 'nl', 'space', 'indentation', ]
        color = CND.grey
      when isxid is true
        color = CND.orange
      else
        color = CND.blue
    #.......................................................................................................
    if cs?
      cs_txt = "#{CND.grey '->'} #{CND.red rpr cs}"
    #.......................................................................................................
    if type in [ 'indent', 'dedent', ]
      level_txt = "level: #{CND.red rpr level}"
    #.......................................................................................................
    info color "#{start}:#{stop} #{type}#{padding} #{rpr image} #{cs_txt} #{level_txt}"
    return token




