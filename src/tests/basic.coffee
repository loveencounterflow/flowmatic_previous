
'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'FLOWMATIC/TESTS/BASIC'
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
TAP.test "indentation (1)", ( T ) ->
  step ( resume ) ->
    urge '''"indentation (1)", ( T ) ->'''
    probe = """
      a
        b
          c
        d
      """
    matcher = """
      (identifier|'a')
      > (identifier|'b')
      > (identifier|'c') <
      (identifier|'d') <
      """
    #.........................................................................................................
    protocol = yield HELPERS.transpile_B probe, resume
    throw error if error?
    help  '\n' + probe
    debug '\n' + protocol
    # urge  '\n' + ( yield HELPERS.transpile_B probe, resume )
    T.ok CND.equals protocol, matcher
    T.end()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "indentation (2)", ( T ) ->
  step ( resume ) ->
    urge '''"indentation (2)", ( T ) ->'''
    probe = """
      a
          b
            c
        d
      """
    matcher = """
      (identifier|'a')
      > > (identifier|'b')
      > (identifier|'c') < <
      (identifier|'d') <
      """
    #.........................................................................................................
    protocol = yield HELPERS.transpile_B probe, resume
    throw error if error?
    help  '\n' + probe
    debug '\n' + protocol
    # urge  '\n' + ( yield HELPERS.transpile_B probe, resume )
    T.ok CND.equals protocol, matcher
    T.end()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "assorted", ( T ) ->
  step ( resume ) ->
    probes_and_matchers = [
      ["f foo-bar","(identifier|'f') (lws|' ') (identifier|'foo-bar')"]
      ["a-b\n\n  a - b","(identifier|'a-b')\n> (identifier|'a') (lws|' ') (identifier|'-') (lws|' ') (identifier|'b') <"]
      ["one + two ** three + f -> 42","(identifier|'one') (lws|' ') (operator|'+') (lws|' ') (identifier|'two') (lws|' ') (operator|'**') (lws|' ') (identifier|'three') (lws|' ') (operator|'+') (lws|' ') (identifier|'f') (lws|' ') (function|'->') (lws|' ') (number|'42')"]
      ["d = ~isa: :foo","(identifier|'d') (lws|' ') (operator|'=') (lws|' ') (key|'~isa') (colon|':') (lws|' ') (keystring|'\\'foo\\'')"]
      ]
    #.........................................................................................................
    for [ probe, matcher, ] in probes_and_matchers
      protocol = yield HELPERS.transpile_B probe, resume
      debug JSON.stringify [ probe, protocol, ]
      T.ok CND.equals protocol, matcher
    T.end()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "assorted 2", ( T ) ->
  step ( resume ) ->
    probes_and_matchers = [
      ["d := expression | '(' + expression + ')'",'']
      ["f'foo'",'']
      ["y{* x *}z",'']
      ["with read-file 'x.txt' as file then f file",'']
      ]
    #.........................................................................................................
    for [ probe, matcher, ] in probes_and_matchers
      protocol = yield HELPERS.transpile_B probe, resume
      urge probe
      help protocol
      # debug JSON.stringify [ probe, protocol, ]
      # T.ok CND.equals protocol, matcher
    T.end()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "strings etc.", ( T ) ->
  step ( resume ) ->
    probes_and_matchers = [
      ["'123'",'']
      ["'''123'''",'']
      ['"123"','']
      ['"""123"""','']
      ['`123`','']
      ['```123```','']
      ["'x'",'']
      ["'''x'''",'']
      ['"x"','']
      ['"""x"""','']
      ['`x`','']
      ['```x```','']
      ["'x y z'",'']
      ["'''x y z'''",'']
      ['"x y z"','']
      ['"""x y z"""','']
      ['`x y z`','']
      ['```x y z```','']
      ]
    #.........................................................................................................
    for [ probe, matcher, ] in probes_and_matchers
      protocol = yield HELPERS.transpile_B probe, resume
      urge probe
      help protocol
      # debug JSON.stringify [ probe, protocol, ]
      # T.ok CND.equals protocol, matcher
    T.end()
  #.........................................................................................................
  return null

  # FLOWMATIC.transpile
  # FLOWMATIC.transpile
  # FLOWMATIC.transpile
  # FLOWMATIC.transpile """
  #   a = [
  #     1
  #     2
  #     3
  #     ]
  #   """
  # FLOWMATIC.transpile """
  #   f = ->
  #     foo
  #     g = ->
  #       bar
  #     h = 42
  #   """


  ###
  FLOWMATIC.transpile """
    aaa ** bbb
    is-first = yes
    type-of-x = CND/type-of x
    a = d/x/g
    d = ~isa: :foo
    e = 1_000_000
    # s{ :d, :j, }
    f = ->
      foo
      bar
    """
  ###

    # foo/bar = 42
    # foo/bar/baz = 42
    # token/type
    # token/$type
    # c = 'a string'
    # c = "a string"
    # # comment
    # ### block comment ###
    # x =
    #   foo: 42
    #   bar: 108


    # """

  # source = 'a?(b: c)'
  # source = """
  # a ° >>>!! b


  # """
  # sources = [ 'a - b\n  c+d', ]
  # sources = []
  # sources.push """
  #   f: =>
  #     say :helo ° :world!§$%&{([]})=
  #     x = ///2///3
  #     yield
  #     await
  #     let
  #     d = ### x ### 42
  #   """

  # sources = []
  # sources.push """
  #   g = ->
  #   \tsay -- helo world
  #   """
  # sources.push """
  #   d: 4 * <unit:3m:>
  #   use 'units'; d: 4 * 3m.
  #   match <text:helo world:>, <re:^.[aeiou]+:>
  #   use 'strings', 'regexes'
  #     match 'helo world', /^.[aeiou]+/

  #   e: <text:::This text contains: single colons!:::>
  #   e: <text|This text contains: single colons!|>
  #   e: <text This text contains: single colons! >
  #   """

  # sources = []
  # sources.push 'a - b'
  # sources.push 'a-b'

  # sources = []
  # sources.push """
  #   d: 4 * <unit:3m:>
  #   e: <text|This text contains: single colons!|>
  #   square: ( x ) <-> x ** 2
  #   """

  # ###
  # for source in sources
  #   help()
  #   show source
  # ###




