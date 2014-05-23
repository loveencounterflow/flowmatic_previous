


### TAINT contains no facilities to load other grammar modules than those contained in Arabika ###


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
#...........................................................................................................
### https://github.com/isaacs/node-glob ###
GLOB                      = require 'glob'

#-----------------------------------------------------------------------------------------------------------
@new_route_info = ( route ) ->
  base_name = njs_path.basename route
  nr        = parseInt ( base_name.replace /^([0-9]+).+/g, '$1' ), 10
  name      = base_name.replace /^[0-9]+-([^.]+).+$/g, '$1'
  # name      = name.replace /-/g, '_'
  name      = name.toUpperCase()
  R         =
    'route':      route
    'name':       name
    'nr':         nr
  #.........................................................................................................
  return R


#-----------------------------------------------------------------------------------------------------------
@get_route_infos = ( options = {} ) ->
  ### Get routes for all grammar modules whose name starts with a digit other than 0: ###
  glob    = njs_path.join __dirname, '*'
  R       = ( route for route in GLOB.sync glob )
  matcher = if options[ 'all' ] then /^[0-9]/ else /^[1-9]/
  R       = ( route for route in R when matcher.test njs_path.basename route )
  R       = ( @new_route_info route for route in R )
  #.........................................................................................................
  R.sort ( a, b ) ->
    a = a[ 'nr' ]
    b = b[ 'nr' ]
    return +1 if a > b
    return -1 if a < b
    return  0
  #.........................................................................................................
  return R

