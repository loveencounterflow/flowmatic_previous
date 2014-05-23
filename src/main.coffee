
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
@_loader                  = require './LOADER'
MULTIMIX                  = require 'coffeenode-multimix'
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



############################################################################################################
route_infos     = @_loader.get_route_infos()
for route_info in route_infos
  { route
    name
    nr    }   = route_info
  throw new Error "duplicate module #{route}:\nname #{rpr name} already in use" if @[ name ]?
  module      = require route
  @[ name ]   = MULTIMIX.bundle module

# module.exports  = MULTIMIX.assemble @, modules...



