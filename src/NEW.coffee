

############################################################################################################
TYPES                     = require 'coffeenode-types'
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
# MULTIMIX                  = require 'coffeenode-multimix'
PADAG                     = require './PADAG'
LODASH                    = require 'lodash'


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
copy = ( value ) ->
  ### Return a deep copy of `value`. ###
  ### TAINT will fail silently for anything but lists and PODs ###
  return LODASH.merge ( if TYPES.isa_list value then [] else {} ), value


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
        if TYPES.isa_function get_rule
          R[ rule_name ] = get_rule R, $
        else
          R[ rule_name ] = get_rule
    #.......................................................................................................
    return R

#-----------------------------------------------------------------------------------------------------------
@grammar = ( target, grammar, options ) ->
  ###

  call as:
    * `ƒ.new.grammar G` with a given grammar to instantiate a new grammar using default options. This
      should never be necessary for standard grammars (that have already instantiated themselves).
    * `ƒ.new.grammar G, $` with a grammar `G` and an options POD `$` to instantiate a grammar with rules
      as given by `G` and settings as given by `$`. This form may be used to obtain a 'parametrized
      modification' of `G`.
    * `ƒ.new.grammar target, G, $` with a `target` object, a grammar, and an options POD; this will
      add missing rules from `G` to `target` and preserve existing methods there. The third argument is
      mandatory to distinguish this signature from the one above, but may be set to `null`.
  ###
  switch arity = arguments.length
    when 1 then [ target, grammar, options, ] = [ {}, target, {},      ]
    when 2 then [ target, grammar, options, ] = [ {}, target, grammar, ]
    when 3 then null
    else
      throw new Error "expected one, two or three arguments, got #{arity}"
  ### In case `G` has a member `grammar`, use that one instead of `G` itself; this allows us to derive
  new grammars by simply saying `ƒ.new.grammar ( require 'foo' ), options`: ###
  grammar   = grammar[ 'grammar' ] if grammar[ 'grammar' ]?
  # options  ?= grammar[ 'options' ]
  target[ 'nodes' ]?= {}
  target[ 'tests' ]?= {}
  target[ 'options' ] = LODASH.merge ( target[ 'options' ] ? {} ), ( options ? {} ), ( grammar[ 'options' ] ? {} )
  debug '###', ( name for name of grammar )
  debug '###', ( name for name of grammar[ 'options' ] )
  debug '###', ( name for name of options )
  debug '###', ( name for name of target[ 'options' ] )
  #.......................................................................................................
  for member_name, member of grammar grammar target, target[ 'options' ]
    whisper name
  #   unless target[ member_name ]?
  #     target[ member_name ] = member
  # for rule_name, get_rule of library[ 'rules' ]
  #   # throw new Error "detected" if is_reserved[ rule_name ]
  #.......................................................................................................
  return target

#-----------------------------------------------------------------------------------------------------------
@consolidate = ( grammar ) ->
  # info grammar
  grammar[ 'nodes' ]?= {}
  grammar[ 'tests' ]?= {}
  constructor = grammar[ 'constructor' ]
  options     = grammar[ 'options' ] ? {}
  throw new Error "unable to find constructor in grammar" unless TYPES.isa_function constructor
  constructor grammar, options
  # info 'options:', ( name for name of options )
  for name, member of grammar
    # info name
    continue if name is 'constructor'
    continue if name is 'nodes'
    continue if name is 'tests'
    continue if name is 'options'
    if TYPES.isa_function member
      grammar[ name ] = member()
      LODASH.merge grammar[ name ], member
      # for subname, submember of member
      #   grammar[ name ][ subname ] = submember

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
@member_expression = ( subtype, computed, object, property, verbatim ) ->
  #.........................................................................................................
  R                 = @_new_node 'MemberExpression', subtype, verbatim
  R[ 'computed'   ] = computed
  R[ 'object'     ] = object
  R[ 'property'   ] = property
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
@_XXX_node = ( grammar, type, subtype ) ->
  ### TAINT method to replace `_new_node` ###
  R =
    type:         type
    'x-subtype':  subtype
    'x-grammar':  grammar
  # R[ 'x-verbatim' ] = verbatim if verbatim?
  # alert "use of verbatim feature discourage at this time: #{rpr verbatim}" if verbatim?
  return R

#-----------------------------------------------------------------------------------------------------------
@_XXX_YYY_node = ( translator, type, subtype ) ->
  ### TAINT method to replace `_new_node` ###
  R =
    type:         type
    'x-subtype':  subtype
    'translator': translator
  return R

#-----------------------------------------------------------------------------------------------------------
@_traverse = ( node, handler ) ->
  ### Traverse a node and all its sub-nodes. We can't use `estraverse` for this task as it does not reliably
  iterate over non-standard nodes. ###
  switch type = TYPES.type_of node
    when 'list'
      @_traverse element, handler for element in node
    when 'pod'
      if node[ 'type' ]?
        handler node
      for ignored, sub_node of node
        # whisper ignored, sub_node
        @_traverse sub_node, handler
  return null

#-----------------------------------------------------------------------------------------------------------
@_delete_grammar_references = ( node ) ->
  ### Remove references to issuing grammar from node, including nested sub-nodes; useful for testing. ###
  @_traverse node, ( sub_node ) ->
    delete sub_node[ 'x-grammar' ]
    delete sub_node[ 'translator' ]
  return node

############################################################################################################
# MULTIMIX.bundle @


