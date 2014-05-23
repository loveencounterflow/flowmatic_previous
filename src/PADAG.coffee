

### TAINT this module could form a separate package ###

### Reads the SpiderMonkey Parser API Type Hierarchy as recorded in `../options.coffee` and constructs a
graph-like structure that gives answers to such questions as 'is a YieldExpression an Expression?' (yes) or
'is a SwitchCase node a Statement? an Expression?' (no and no). ###


############################################################################################################
# njs_util                  = require 'util'
# njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'tsort'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
echo                      = TRM.echo.bind TRM
rainbow                   = TRM.rainbow.bind TRM
raw_dependencies          = ( require '../options' )[ 'parserapi' ][ 'dependencies' ]
new_tsort_graph           = require 'tsort'

#-----------------------------------------------------------------------------------------------------------
new_dependencies_graph = ->
  matcher   = /// ^ \s* ( [^\s<]+ ) \s* <? \s* ( .* ) $ ///
  splitter  = /// \s* , \s* ///
  g         = new_tsort_graph()
  R         = {}
  for raw_dependency in raw_dependencies
    # debug raw_dependency
    match = raw_dependency.match matcher
    throw new Error "syntax error: #{rpr raw_dependency}" unless match?
    [ ignored
      descendant
      rhs         ]       = match
    ancestors_list        = ( ancestor for ancestor in rhs.split splitter when ancestor.length > 0 )
    ancestors             = {}
    R[ descendant ]       = ancestors
    for ancestor in ancestors_list
      ancestors[ ancestor ] = 1
      g.add descendant, ancestor
  #.........................................................................................................
  for descendant in g.sort().reverse()
    for ancestor of ancestors = R[ descendant ]
      for predecessor of R[ ancestor ]
        ancestors[ predecessor ] = 1
  #.........................................................................................................
  return R
  # info g.sort().reverse()

g = new_dependencies_graph()

#-----------------------------------------------------------------------------------------------------------
@derives_from = ( descendant, ancestor ) ->
  ancestors     = g[ descendant ]
  predecessors  = g[ ancestor   ]
  throw new Error "unknown parser API type: #{rpr descendant}"  unless ancestors?
  throw new Error "unknown parser API type: #{rpr ancestor}"    unless predecessors?
  return ancestors[ ancestor ]?

#-----------------------------------------------------------------------------------------------------------
@isa_statement = ( node ) ->
  return @derives_from node[ 'type' ], 'Statement'

#-----------------------------------------------------------------------------------------------------------
@isa_expression = ( node ) ->
  return @derives_from node[ 'type' ], 'Expression'

############################################################################################################
unless module.parent?
  # demo()
  # new_dependencies_graph()

  log @derives_from 'LetExpression', 'Node'
  log @derives_from 'LetExpression', 'Statement'
  log @derives_from 'ExpressionStatement', 'Statement'
  log @derives_from 'ExpressionStatement', 'Expression'
  log @isa_expression type: 'ExpressionStatement'
  log @isa_statement  type: 'ExpressionStatement'
  log @isa_statement  type: 'IfStatement'
  log @isa_statement  type: 'BlockStatement'









