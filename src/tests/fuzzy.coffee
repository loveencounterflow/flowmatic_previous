
'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'FLOWMATIC/TESTS/FUZZY'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
TAP                       = require 'tap'
#...........................................................................................................
FLOWMATIC                 = require '../..'
PS                        = require 'pipestreams'
{ $, $async, }            = PS
{ step, }                 = require 'coffeenode-suspend'


### TAINT refactor HELPERS ###

#-----------------------------------------------------------------------------------------------------------
HELPERS = {}

#-----------------------------------------------------------------------------------------------------------
HELPERS.transpile_text_to_protocol = ( text, protocol_transform, handler ) ->
  pipeline  = []
  Ø         = ( x ) => pipeline.push x
  #.........................................................................................................
  # Ø PS.new_file_source './sample.xcoffee'; Ø PS.$join(); Ø map ( buffer ) -> buffer.toString 'utf-8' # ... and decode
  # Ø @$transpile_to_cs_tokens()
  # Ø @$show()
  # Ø @$cs_tokens_as_text()
  # Ø @$cs_text_as_js()
  Ø PS.new_text_source text
  Ø FLOWMATIC.LEXER.$lex()
  Ø FLOWMATIC.ARABIKA.$transpile()
  Ø protocol_transform
  #.........................................................................................................
  Ø do =>
    Z = []
    return $ 'null', ( collection, send ) ->
      if collection? then send Z = collection
      else handler null, Z
      return null
  #.........................................................................................................
  Ø PS.$drain()
  PS.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
HELPERS.transpile_A = ( text, handler ) ->
  step ( resume ) ->
    recorder = FLOWMATIC.PROTOCOL.$cs_tokens_as_protocol_A()
    protocol = yield HELPERS.transpile_text_to_protocol text, recorder, resume
    handler null, protocol

#-----------------------------------------------------------------------------------------------------------
HELPERS.transpile_B = ( text, handler ) ->
  step ( resume ) ->
    recorder = FLOWMATIC.PROTOCOL.$cs_tokens_as_protocol_B()
    protocol = yield HELPERS.transpile_text_to_protocol text, recorder, resume
    handler null, protocol


#-----------------------------------------------------------------------------------------------------------
TAP.test "random stuff", ( T ) ->
  Randex  = require 'randexp'
  randex  = new Randex /[-\x20a-z0-9()\[\]§$%^°+*´`=?]{0,150}/
  step ( resume ) ->
    for i in [ 0 .. 10 ]
      probe = randex.gen()
      protocol = yield HELPERS.transpile_B probe, resume
      urge probe
      help protocol
    T.end()
  #.........................................................................................................
  return null



