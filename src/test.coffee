


############################################################################################################
# njs_util                  = require 'util'
njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = '﴾test﴿'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
urge                      = TRM.get_logger 'urge',      badge
praise                    = TRM.get_logger 'praise',    badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
NEW                       = require './NEW'
LOADER                    = require './grammar-loader'
assert                    = require 'assert'
#...........................................................................................................
BNP                       = require 'coffeenode-bitsnpieces'
ESCODEGEN                 = require 'escodegen'
escodegen_options         = ( require '../options' )[ 'escodegen' ]

#-----------------------------------------------------------------------------------------------------------
@test =

  #---------------------------------------------------------------------------------------------------------
  ok: ( result ) =>
    ### Tests whether `result` is strictly `true` (not only true-ish). ###
    throw new Error "expected true, got\n#{rpr result}" unless result is true

  #---------------------------------------------------------------------------------------------------------
  fail: ( message ) =>
    throw new Error message

  #---------------------------------------------------------------------------------------------------------
  eq: ( P... ) =>
    ### Tests whether all arguments are pairwise and deeply equal. Uses CoffeeNode Bits'n'Pieces' `equal`
    for testing as (1) Node's `assert` distinguishes—unnecessarily—between shallow and deep equality, and,
    worse, [`assert.equal` and `assert.deepEqual` are broken](https://github.com/joyent/node/issues/7161),
    as they use JavaScript's broken `==` equality operator instead of `===`. ###
    # throw new Error "not equal: \n#{( rpr p for p in P ).join '\n'}" unless BNP.equals P...
    throw new Error "not equal: \n#{( JSON.stringify p for p in P ).join '\n'}" unless BNP.equals P...

  #---------------------------------------------------------------------------------------------------------
  as_js: ( node ) =>
    ### Given a SpiderMonkey Parser API-compliant `node` object, returns the corresponding JavaScript
    source code as results from applying EsCodeGen (with the settings as detailed in `options.coffee`);
    this is handy to do a quick sanity check on expected translation results. ###
    return ESCODEGEN.generate node, escodegen_options

  #---------------------------------------------------------------------------------------------------------
  throws: assert.throws.bind assert

#-----------------------------------------------------------------------------------------------------------
@_matches_filter = ( nr, module_name, matchers ) ->
  return yes if matchers.length is 0
  for matcher in matchers
    return yes if matcher is "#{nr}"
    return yes if matcher.test? and matcher.test module_name
  return no

#-----------------------------------------------------------------------------------------------------------
@main = ->
  route_infos   = LOADER.get_route_infos all: yes
  route_count   = route_infos.length
  skip_count    = 0
  test_count    = 0
  pass_count    = 0
  fail_count    = 0
  miss_count    = 0
  matchers      = []
  for m in process.argv[ 2 .. ]
    unless /^[0-9]+$/.test m
      m = new RegExp ".*#{BNP.escape_regex m}.*"
    matchers.push m
  #.........................................................................................................
  for route_info in route_infos
    { route, name: module_name, nr } = route_info
    unless @_matches_filter nr, module_name, matchers
      whisper "skipping #{nr}-#{module_name}"
      skip_count += 1
      continue
    info ( rpr nr ) + '-' + module_name
    module = require route
    #.......................................................................................................
    unless ( TESTS = module[ '$TESTS' ] )?
      miss_count += 1
      urge "no tests found for #{nr}-#{module_name} (#{route})"
      continue
    #.......................................................................................................
    for test_name of TESTS
      test_count += 1
      locator     = ( rpr nr ) + '-' + module_name + '/' + test_name
      try
        TESTS[ test_name ].call module, @test
      catch error
        fail_count += 1
        warn "#{locator}:"
        warn error[ 'message' ]
        continue
      #.....................................................................................................
      pass_count += 1
      praise "#{locator}"
  #.........................................................................................................
  whisper '-------------------------------------------------------------'
  info    "Skipped #{skip_count} out of #{route_count} modules;"
  info    "of the #{route_count - skip_count} modules inspected,"
  urge    "#{miss_count} modules had no test cases."
  info    "In the remaining #{route_count - miss_count - skip_count} modules,"
  info    "#{test_count} tests were performed,"
  praise  "of which #{pass_count} tests passed,"
  warn    "and #{fail_count} tests failed."
  whisper '-------------------------------------------------------------'
  #.........................................................................................................
  return null



############################################################################################################
@main() unless module.parent?


