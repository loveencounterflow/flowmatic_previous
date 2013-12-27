
############################################################################################################
# njs_util                  = require 'util'
# njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
# CHR                       = require 'coffeenode-chr'
# BAP                       = require 'coffeenode-bitsnpieces'
TYPES                     = require 'coffeenode-types'
TEXT                      = require 'coffeenode-text'
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'XLTX'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
echo                      = TRM.echo.bind TRM
# rainbow                   = TRM.rainbow.bind TRM
# suspend                   = require 'coffeenode-suspend'
# step                      = suspend.step
# after                     = suspend.after
# eventually                = suspend.eventually
# immediately               = suspend.immediately
# every                     = suspend.every
#...........................................................................................................
# MONA                      = require '/Volumes/Storage/cnd/node_modules/coffeenode-flowmatic/node_modules/mona-parser'
# MONA                      = require 'mona-parser'
### TAINT why can't we `require` without route??? ###
### https://github.com/sykopomp/mona ###
MONA                      = require '../node_modules/mona-parser'

# TRM.dir MONA

#-----------------------------------------------------------------------------------------------------------
csv = ->
  MONA.splitEnd line(), eol()

#-----------------------------------------------------------------------------------------------------------
line = ->
  MONA.split cell(), MONA.string ','

#-----------------------------------------------------------------------------------------------------------
cell = ->
  MONA.or quotedCell(), ( MONA.text ( MONA.noneOf ',\n\r' ) )

#-----------------------------------------------------------------------------------------------------------
quotedCell = ->
  MONA.between ( MONA.string '"' ), ( MONA.string '"' ), ( MONA.text quotedChar() )

#-----------------------------------------------------------------------------------------------------------
quotedChar = ->
  MONA.or ( MONA.noneOf '"' ), ( MONA.and ( MONA.string '""' ), ( MONA.value '"' ) )

#-----------------------------------------------------------------------------------------------------------
eol = ->
  str = MONA.string
  MONA.or ( str '\n\r' ), ( str '\r\n' ), ( str '\n' ), ( str '\r' ), "end of line"

#-----------------------------------------------------------------------------------------------------------
parseCSV = ( source ) ->
  return parse csv(), source

#-----------------------------------------------------------------------------------------------------------
parse = ( parser, source, options ) ->
  #.........................................................................................................
  try
    MONA.parse parser, source, options
  #.........................................................................................................
  catch error
    position    = error[ 'position'   ]
    # throw error unless position?
    name        = position?[ 'name'    ]
    line_nr     = position?[ 'line'    ]
    column_nr   = position?[ 'column'  ]
    #.......................................................................................................
    if line_nr? and column_nr?
      line = ( TEXT.lines_of source )[ line_nr - 1 ]
      file = "in #{name} " ? ''
      warn "Error #{file}on line ##{line_nr}, column #{column_nr}:"
      warn line
      warn ( ( new Array column_nr ).join ' ' ).concat '^'
    #.......................................................................................................
    throw error

#-----------------------------------------------------------------------------------------------------------
parenthesized = ( parser ) ->
  MONA.sequence ( s ) ->
    open  = s MONA.string '('
    data  = s parser
    close = s MONA.string ')'
    return MONA.value data


# => "foo!"

############################################################################################################
info parseCSV """
  foo,"bar"
  baz,quux\n"""
# info parseCSV """
#   foo,"b"a"r"
#   baz,quux
#   """

# => [['foo', 'bar'], ['b"az', 'quux']]

# info parse MONA.fail(), """helo"""
# info parse MONA.token(), """h"""
info parse ( MONA.value """just a value""" ), ''
info parse ( parenthesized MONA.string "foo!" ), "(foo!)"
# info parse ( parenthesized MONA.string "foo!" ), "(bar!)", fileName: '/tmp/unknown.txt'
info parse MONA.float(), "34.556"
info parse MONA.float(), "34.556e10"


