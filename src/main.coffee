
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
@_new                     = require './NEW'
@_loader                  = require './grammar-loader'
MULTIMIX                  = require 'coffeenode-multimix'



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

