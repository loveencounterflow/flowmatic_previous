

############################################################################################################
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = '﴾new﴿'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
MULTIMIX                  = require 'coffeenode-multimix'
PADAG                     = require './PADAG'



#===========================================================================================================
# NEW GRAMMAR
#-----------------------------------------------------------------------------------------------------------
@new = ( library ) ->
  return ( G, $ ) ->
    if ( arity = arguments.length ) is 1
      [ G, $, ] = [ null, G, ]
    $          ?= {}
    $[ name ]  ?= value for name, value of library[ '$' ]
    R           = G ? {}
    R[ '$' ]    = $
    #.......................................................................................................
    for rule_name, get_rule of library[ '$new' ]
      unless R[ rule_name ]?
        R[ rule_name ] = get_rule R, $
    #.......................................................................................................
    return R


#===========================================================================================================
# STANDARD PARSER API NODES
#-----------------------------------------------------------------------------------------------------------
@binary_expression = ( subtype, operator, left, right, verbatim ) ->
  R                 = @_new_node 'BinaryExpression', subtype, verbatim
  R[ 'operator'   ] = operator
  R[ 'left'       ] = left
  R[ 'right'      ] = right
  return R

#-----------------------------------------------------------------------------------------------------------
@expression_statement = ( subtype, expression, verbatim ) ->
  #.........................................................................................................
  R                 = @_new_node 'ExpressionStatement', subtype, verbatim
  R[ 'expression' ] = expression
  return R

#-----------------------------------------------------------------------------------------------------------
@block_statement = ( subtype, body, verbatim ) ->
  # alert '©445', body
  for node, idx in body
    whisper '©521', node, idx
    if PADAG.isa_expression node
      # whisper "expression: #{JSON.stringify node}"
      body[ idx ] = @expression_statement 'auto', node
  #.........................................................................................................
  R                 = @_new_node 'BlockStatement', subtype, verbatim
  R[ 'body'       ] = body
  return R

#-----------------------------------------------------------------------------------------------------------
@identifier = ( subtype, name, verbatim ) ->
  R                 = @_new_node 'Identifier', subtype, verbatim
  R[ 'name'       ] = name
  return R

#-----------------------------------------------------------------------------------------------------------
@literal = ( subtype, raw, value, verbatim ) ->
  R                 = @_new_node 'Literal', subtype, verbatim
  R[ 'raw'        ] = raw
  R[ 'value'      ] = value
  return R


#===========================================================================================================
# ADDITIONAL NODES
#-----------------------------------------------------------------------------------------------------------
@x_comment = ( text, subtype = 'comment' ) ->
  ### TAINT don't use `verbatim` here as it is target-language specific ###
  # verbatim = '/* ' + ( text.replace /\/\*/g, '/ *' ) + ' */'
  # return @literal subtype, 'xxx', 'xxx', verbatim
  return @literal subtype, text, text

# #-----------------------------------------------------------------------------------------------------------
# @x_indentation = ( text, level ) ->
#   ### TAINT make annotation of indentation an option ###
#   verbatim = "/* indentation level #{level} */"
#   R = @literal subtype, 'xxx', 'xxx', verbatim
#   R[ 'x-level' ] = level

#-----------------------------------------------------------------------------------------------------------
@x_use_statement = ( keyword, argument ) ->
  text = "#{keyword} #{rpr argument}"
  return @x_comment text, 'use-statement'

#-----------------------------------------------------------------------------------------------------------
@x_symbol = ( mark, raw, value ) ->
  R             = @_new_node 'Literal', 'symbol'
  R[ 'x-mark'     ] = mark
  R[ 'raw'        ] = raw
  R[ 'value'      ] = value
  return R

#-----------------------------------------------------------------------------------------------------------
@x_relative_route = ( raw, value ) ->
  R             = @_new_node 'Literal', 'relative-route'
  R[ 'raw'        ] = raw
  R[ 'value'      ] = value
  return R

#-----------------------------------------------------------------------------------------------------------
@x_identifier_with_sigil = ( sigil, name ) ->
  R                 = @_new_node 'Identifier', 'identifier-with-sigil'
  R[ 'x-sigil'    ] = sigil
  R[ 'name'       ] = name
  return R

#-----------------------------------------------------------------------------------------------------------
@x_identifier_without_sigil = ( name ) ->
  R                 = @_new_node 'Identifier', 'identifier-without-sigil'
  R[ 'name'       ] = name
  return R


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@_new_node = ( type, subtype, verbatim ) ->
  R =
    type:         type
    'x-subtype':  subtype
  R[ 'x-verbatim' ] = verbatim if verbatim?
  alert "use of verbatim feature discourage at this time: #{rpr verbatim}" if verbatim?
  return R

#-----------------------------------------------------------------------------------------------------------
@_add_verbatim = ( node, verbatim ) ->


############################################################################################################
MULTIMIX.bundle @


