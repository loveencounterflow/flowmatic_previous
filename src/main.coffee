
############################################################################################################
# njs_util                  = require 'util'
njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = '﴾main﴿'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
echo                      = TRM.echo.bind TRM
rainbow                   = TRM.rainbow.bind TRM
#...........................................................................................................
@new                      = require './new'
# @_loader                  = require './LOADER'
MULTIMIX                  = require 'coffeenode-multimix'
ƒ                         = @
π                         = require 'coffeenode-packrattle'
# info ( name for name of @ ).sort().join ' '
# info ( name for name of π ).sort().join ' '

# @Match              = π.Match.bind            π
# @NoMatch            = π.NoMatch.bind          π
# @Parser             = π.Parser.bind           π
# @ParserState        = π.ParserState.bind      π
# @PriorityQueue      = π.PriorityQueue.bind    π
# @newParser          = π.newParser.bind        π
@or                 = π.alt #.bind              π
@chain              = π.chain #.bind            π
@check              = π.check #.bind            π
@commit             = π.commit #.bind           π
@consume            = π.consume #.bind          π
@drop               = π.drop #.bind             π
@end                = π.end #.bind              π
@not_               = π.not_ #.bind             π
@optional           = π.optional #.bind         π
@parse              = π.parse #.bind            π
@reduce             = π.reduce #.bind           π
@regex              = π.regex #.bind            π
@reject             = π.reject #.bind           π
@repeat             = π.repeat #.bind           π
@repeatIgnore       = π.repeatIgnore #.bind     π
@repeatSeparated    = π.repeatSeparated #.bind  π
@seq                = π.seq #.bind              π
@seqIgnore          = π.seqIgnore #.bind        π
@string             = π.string #.bind           π
@succeed            = π.succeed #.bind          π

#-----------------------------------------------------------------------------------------------------------
@match = ( hint ) ->
  ### Convenience method to match either a text, a RegEx, or a deferred function. ###

#-----------------------------------------------------------------------------------------------------------
@xre = ( hint ) ->

#-----------------------------------------------------------------------------------------------------------
@on = ( hint ) ->
  ### Method to replace `.onMatch` and `onFail`. ###

#-----------------------------------------------------------------------------------------------------------
@as = ( target_language_name, node ) ->
  translator = @as[ target_language_name ]
  throw new Error "unknown target language #{rpr target_language_name}" unless translator?
  return translator node

#-----------------------------------------------------------------------------------------------------------
@as._collect_taints = ( translations... ) ->
  taints = {}
  for translation in translations
    continue unless ( taints = translation[ 'taints'] )?
    taints[ taint ] = 1 for taint in taints
  return taints

#-----------------------------------------------------------------------------------------------------------
@as.coffee = ( node ) ->
  # debug '©3412', node[ 'type' ] + '/' + node[ 'x-subtype' ]
  # debug '©3412', node[ 'x-grammar' ]?
  # debug '©3412', node[ 'translator' ]?
  ### TAINT call to grammar.as.coffee to be phased out ###
  return grammar.as.coffee node if ( grammar = node[ 'x-grammar' ] )?
  return translator.coffee node if ( translator = node[ 'translator' ] )?
  return translator.coffee node if ( translator = node[ '%translator' ] )?
  type    = node[ 'type' ]
  type   += '/' + node[ 'x-subtype' ] if node[ 'x-subtype' ]?
  throw new Error "unable to find translator for #{type}"
  # ### TAINT stopgap solution ###
  # target  = if node[ 'value' ]? then rpr @new._delete_grammar_references node[ 'value' ] else rpr @new._delete_grammar_references node
  # target  = if node[ 'value' ]? then rpr node[ 'value' ] else rpr node
  taints  = {}
  taints[ "unable to find translator for #{type}" ] = 1
  return target: target, taints: taints

#-----------------------------------------------------------------------------------------------------------
@as.coffee.target = ( translations... ) ->
  ### TAINT what about indentation? ###
  taints  = ƒ.as.coffee.taints translations...
  R       = [ taints, ]
  R.push translation[ 'target' ] for translation in translations
  return R.join ''

#-----------------------------------------------------------------------------------------------------------
@as.coffee.taints = ( translations... ) ->
  taints = ƒ.as._collect_taints translations...
  taints = ( taint for taint of taints ).sort()
  return ( ( "### #{taint} ###\n" for taint in taints ).join '' )



# ############################################################################################################
# route_infos     = @_loader.get_route_infos()
# for route_info in route_infos
#   { route
#     name
#     nr    }   = route_info
#   throw new Error "duplicate module #{route}:\nname #{rpr name} already in use" if @[ name ]?
#   module      = require route
#   @[ name ]   = MULTIMIX.bundle module

# # module.exports  = MULTIMIX.assemble @, modules...



