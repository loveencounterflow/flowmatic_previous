

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'DEMO-COFFEE-LEX'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
PS                        = require '../../pipestreams'
{ $, map, }               = PS
CS                        = require 'coffeescript'
#...........................................................................................................
@U                        = require './utilities'
@LEXER                    = require './lexer'
@PROTOCOL                 = require './protocol'
@ARABIKA                  = require './basic-arabika'

# { default: lex, SourceType, } = require '../../coffee-lex'


# #-----------------------------------------------------------------------------------------------------------
# @_image_from_section      = ( section ) -> ( token.image for token in section ).join ''
# @_typeimage_from_section  = ( section ) -> ( token.type  for token in section ).join ','

# #-----------------------------------------------------------------------------------------------------------
# @$exponentiation = ->
#   return PS.$gliding_window 4, ( section ) =>
#     image = @_image_from_section section
#     if image is ' ** '
#       ### TAINT use proper method ###
#       section[ 1 .. 2 ] = { type: 'operator', start: 0, stop: 0, image: '**', specifier: 'operator/**' }
#     return null

# #-----------------------------------------------------------------------------------------------------------
# @$xidentifiers = ->
#   send          = null
#   id_collector  = []
#   id_start      = null
#   #.........................................................................................................
#   flush = ->
#     if ( id_count = id_collector.length ) > 0
#       image               = id_collector.join ''
#       stop                = id_start + id_count
#       send { start: id_start, stop, type: 'identifier', image, isxid: yes, count: id_count, }
#       id_collector.length = 0
#       id_start            = null
#     return null
#   #.........................................................................................................
#   return $ 'null', ( token, send_ ) =>
#     send = send_
#     if token?
#       { image, start, isxid, } = token
#       if isxid
#         id_start ?= start
#         id_collector.push image
#       else
#         flush()
#         send token
#     else
#       flush()
#     return null

# #-----------------------------------------------------------------------------------------------------------
# @$relabel_slash = ->
#   return map ( token ) =>
#     if token.image is '/' then token.type = 'slash'
#     return token

# #-----------------------------------------------------------------------------------------------------------
# @$slash_as_dot = ->
#   return PS.$gliding_window 3, ( section ) =>
#     # debug '33309', ( rpr @_typeimage_from_section section ), section
#     typeimage = @_typeimage_from_section section
#     if typeimage is 'identifier,slash,identifier'
#       section[ 1 ].type = 'slashdot'
#     return null

# #-----------------------------------------------------------------------------------------------------------
# @$number_with_underscores = ->
#   ### acc. to http://www.regular-expressions.info/floatingpoint.html ###
#   pattern = /^_[_0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?$/
#   return PS.$gliding_window 2, ( section ) =>
#     # debug '33309', ( rpr @_typeimage_from_section section ), section
#     typeimage = @_typeimage_from_section section
#     if typeimage is 'number,identifier'
#       [ t0, t1, ] = section
#       if pattern.test t1.image
#         start             = t0.start
#         stop              = t1.stop
#         image             = t0.image + t1.image
#         cs                = image.replace /_/g, ''
#         blank             = no
#         isxid             = no
#         type              = 'number'
#         new_token         = { start, stop, type, image, cs, blank, isxid, }
#         section[ 0 .. 1 ] = new_token
#     return null

# #-----------------------------------------------------------------------------------------------------------
# @$key_with_sigil = ->
#   sigils = [ '~', '%', ]
#   return PS.$gliding_window 4, ( section ) =>
#     # debug '33309', ( rpr @_typeimage_from_section section ), section
#     [ t0, t1, t2, t3, ] = section
#     if t0.image in sigils and t1.type is 'identifier' and t2.image is ':' and t3.blank
#       # debug '55542', JSON.stringify section
#       start             = t0.start
#       stop              = t1.stop
#       image             = t0.image + t1.image
#       cs                = rpr image
#       blank             = no
#       isxid             = no
#       type              = 'key'
#       new_token         = { start, stop, type, image, cs, blank, isxid, }
#       section[ 0 .. 1 ] = new_token
#     return null

# #-----------------------------------------------------------------------------------------------------------
# @$keystring = ->
#   prv_blank = yes
#   return PS.$gliding_window 3, ( section ) =>
#     # debug '33309', ( rpr @_typeimage_from_section section ), section
#     [ t0, t1, t2, ] = section
#     # debug '33340', section
#     # debug '33340', prv_blank, t0.image, t1.type
#     # debug '33340', prv_blank, t0.image is ':', t1.type is 'identifier'
#     if t0.blank and ( t1.image is ':' ) and ( t2.type is 'identifier' )
#       # debug '55542', JSON.stringify section
#       start             = t1.start
#       stop              = t2.stop
#       image             = rpr t2.image
#       blank             = no
#       isxid             = no
#       type              = 'keystring'
#       new_token         = { start, stop, type, image, blank, isxid, }
#       section[ 1 .. 2 ] = new_token
#     return null

# #-----------------------------------------------------------------------------------------------------------
# @_$translate_slashdot = ->
#   return PS.$gliding_window 3, ( section ) =>
#     typeimage = @_typeimage_from_section section
#     if typeimage is 'identifier,slashdot,identifier'
#       section[ 1 ].type = 'dot'
#       section[ 1 ].cs   = '.'
#     return null

# #-----------------------------------------------------------------------------------------------------------
# @_$translate_dashed_identifier = ->
#   return map ( token ) ->
#     # debug '44498', JSON.stringify token
#     { type, image, } = token
#     if type is 'identifier'
#       cs_image = image.replace /-/g, '_'
#       token.cs = cs_image if cs_image isnt image
#     return token

# #-----------------------------------------------------------------------------------------------------------
# @$transpile_to_cs_tokens = ->
#   pipeline = []
#   # pipeline.push PS.$show()
#   pipeline.push @_$translate_slashdot()
#   pipeline.push @_$translate_dashed_identifier()
#   return PS.pull pipeline...

# #-----------------------------------------------------------------------------------------------------------
# @$cs_tokens_as_text = ->
#   pipeline = []
#   # pipeline.push PS.$show()
#   pipeline.push map ( token ) ->
#     { image, cs, } = token
#     return cs ? image
#   pipeline.push PS.$join()
#   return PS.pull pipeline...

# #-----------------------------------------------------------------------------------------------------------
# @$cs_tokens_as_protocol = ->
#   collector = []
#   return $ 'null', ( token, send ) ->
#     if token?
#       { start, stop, type, image, } = token
#       collector.push "#{start}:#{stop},#{type},#{rpr image}"
#     else
#       send collector.join '\n'
#     return null

# #-----------------------------------------------------------------------------------------------------------
# @$cs_text_as_js = ->
#   return map ( cs_text ) -> CS.compile cs_text

# #-----------------------------------------------------------------------------------------------------------
# @$show = ->
#   return map ( token ) ->
#     { start
#       stop
#       type
#       image
#       isxid
#       cs
#       level } = token
#     #.......................................................................................................
#     start     = rpr start; start   = ' ' + start while start.length < 3
#     stop      = rpr stop ; stop    = ' ' + stop  while  stop.length < 3
#     padding   = ' '.repeat 20 - type.length
#     cs_txt    = ''
#     level_txt = ''
#     #.......................................................................................................
#     switch
#       when type in [ 'indent', 'dedent', ]
#         color = CND.steel
#       when type in [ 'lws', 'nl', 'space', 'indentation', ]
#         color = CND.grey
#       when isxid is true
#         color = CND.orange
#       else
#         color = CND.blue
#     #.......................................................................................................
#     if cs?
#       cs_txt = "#{CND.grey '->'} #{CND.red rpr cs}"
#     #.......................................................................................................
#     if type in [ 'indent', 'dedent', ]
#       level_txt = "level: #{CND.red rpr level}"
#     #.......................................................................................................
#     info color "#{start}:#{stop} #{type}#{padding} #{rpr image} #{cs_txt} #{level_txt}"
#     return token


# #-----------------------------------------------------------------------------------------------------------
# @transpile = ( text, handler ) ->
#   #.........................................................................................................
#   pipeline  = []
#   Ø         = ( x ) => pipeline.push x
#   Ø PS.new_text_source text
#   ###
#   Ø PS.new_file_source './sample.xcoffee'; Ø PS.$join(); Ø map ( buffer ) -> buffer.toString 'utf-8' # ... and decode
#   ###
#   Ø FLOWMATIC.LEXER$lex()
#   #.........................................................................................................
#   Ø @$exponentiation()
#   Ø @$xidentifiers()
#   Ø @$key_with_sigil()
#   Ø @$keystring()
#   Ø @$relabel_slash()
#   Ø @$slash_as_dot()
#   Ø @$number_with_underscores()
#   #.........................................................................................................
#   Ø @$transpile_to_cs_tokens()
#   Ø @$show()
#   # Ø @$cs_tokens_as_text()
#   Ø @$cs_tokens_as_protocol()
#   Ø do =>
#     Z = []
#     return $ 'null', ( collection, send ) ->
#       if collection? then send Z = collection
#       else handler null, Z
#       return null
#   # Ø map ( text ) ->
#   #   urge '\n' + text
#   #   return text
#   ###
#   Ø @$cs_text_as_js()
#   # Ø PS.$show()
#   Ø map ( text ) ->
#     help '\n' + text
#     return text
#   ###
#   Ø PS.$drain()
#   #.........................................................................................................
#   PS.pull pipeline...
#   return null

