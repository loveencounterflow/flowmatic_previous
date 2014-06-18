


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
# $new                      = require './new'
LOADER                    = require './LOADER'
assert                    = require 'assert'
#...........................................................................................................
docopt                    = ( require 'docopt' ).docopt
BNP                       = require 'coffeenode-bitsnpieces'
# ESCODEGEN                 = require 'escodegen'
# escodegen_options         = ( require '../options' )[ 'escodegen' ]
@new                      = require './new'
#...........................................................................................................
@cl_options               = null


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
    values = []
    for p in P
      @new._delete_grammar_references p
      values.push rpr p
    throw new Error "not equal: \n#{values.join '\n'}" unless BNP.equals P...
    # throw new Error "not equal: \n#{( ( rpr p )[ .. 250 ] for p in P ).join '\n'}" unless BNP.equals P...
    # throw new Error "not equal: \n#{( JSON.stringify p for p in P ).join '\n'}" unless r

  # #---------------------------------------------------------------------------------------------------------
  # as_js: ( node ) =>
  #   ### Given a SpiderMonkey Parser API-compliant `node` object, returns the corresponding JavaScript
  #   source code as results from applying EsCodeGen (with the settings as detailed in `options.coffee`);
  #   this is handy to do a quick sanity check on expected translation results. ###
  #   return ESCODEGEN.generate node, escodegen_options

  #---------------------------------------------------------------------------------------------------------
  throws: assert.throws.bind assert

#-----------------------------------------------------------------------------------------------------------
@_matches_filter = ( nr, module_name, hints ) ->
  return ( nr isnt 0 ) if hints.length is 0
  for hint in hints
    return yes if hint is "#{nr}"
    return yes if hint.test? and hint.test module_name
  return no

#-----------------------------------------------------------------------------------------------------------
@main = ->
  # if TYPES.isa_text cl_options
  #   help cl_options
  # whisper cl_options[ '--long-errors' ]
  # process.exit()
  #.........................................................................................................
  route_infos   = LOADER.get_route_infos 'is-tty': yes
  route_count   = route_infos.length
  skip_count    = 0
  test_count    = 0
  pass_count    = 0
  fail_count    = 0
  miss_count    = 0
  hints         = @cl_options[ '<hints>' ]
  #.........................................................................................................
  whisper "matching modules with #{( rpr m for m in hints ).join ', '}" unless hints.length is 0
  for m, idx in hints
    unless /^[0-9]+$/.test m
      if m is '+'
        m = /.*/
      else
        m = new RegExp ".*#{BNP.escape_regex m}.*", 'i'
    hints[ idx ] = m
  # whisper hints
  #.........................................................................................................
  for route_info in route_infos
    { route, name: module_name, nr } = route_info
    unless @_matches_filter nr, module_name, hints
      whisper "skipping #{nr}-#{module_name}"
      skip_count += 1
      continue
    info ( rpr nr ) + '-' + module_name
    module = require route
    #.......................................................................................................
    ### TAINT reference to `$TESTS` to be removed ###
    TESTS = module[ '$TESTS' ] ? module[ 'tests' ]
    unless TESTS? and ( test_names = ( test_name for test_name of TESTS ) ).length > 0
      miss_count += 1
      urge "no tests found for #{nr}-#{module_name} (#{route})"
      continue
    #.......................................................................................................
    for test_name in test_names
      test_count += 1
      locator     = ( rpr nr ) + '-' + module_name + '/' + test_name
      try
        TESTS[ test_name ].call module, @test
      catch error
        fail_count += 1
        warn "#{locator}:"
        if @cl_options[ '--long-errors' ]
          warn error[ 'stack' ]
        else
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
unless module.parent?
  usage = """
  Usage: test [options] [<hints>]...

  Options:
    -l, --long-errors       Show error messages with stacks.
    -h, --help
    -v, --version
  """
  @cl_options = docopt usage, version: ( require '../package.json' )[ 'version' ]
  @main()

