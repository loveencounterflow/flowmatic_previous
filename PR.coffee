


############################################################################################################
$                         = exports ? here
self                      = ( fetch 'library/barista' ).foo __filename
log                       = self.log
log_ruler                 = self.log_ruler
stop                      = self.STOP
_   = $._                 = {}
$.$ = $$                  = {}
#-----------------------------------------------------------------------------------------------------------
format                    = ( require 'sprintf' ).sprintf
h                         = HTML.tags

[_$, __] = [$, _]
$ = PR = {}

$[ '~about' ] = """

  The local PR library (short for 'precedence registry' ) is used for bookkeeping which functions have which
  level of precedence. Precedencies regulate how expressions with several functioncalls are evaluated.

  A simple example: We want the ``:`` (single colon) to act as a general assignment operator, ``::`` (double
  colon) to act as a text value assignment operator *with* string interpolation, and ``:::`` (triple colon)
  to act as a text value assignment operator *without* string interpolation, as shown here:

    a:      42
    b::     helo $name # yields ``b = 'helo fred'`` or similar; this comment is *not* part of the text
    c:::    helo $name # yields ``c = 'helo $name # yields...'``—comment is now in the text

  The fundamental vows for function calls are::

  * When a function gets called with argument expressions, those arguments are evaluated first, then their
    values are passed into the function.

  * It is possible to define a function such that their arguments are *not* evaluated; instead, the function
    receives a single argument which is a *description* of the arguments; it can then choose to evaluate
    any expressions therein (most often in the caller's scope, but that is optional), or it can just take
    the original text of the arguments, as they got written down in the source, and work on that text.

  The last stipulation might strike computer language fans as quite unusual (and certainly as highly
  unpythonic), but, in fact, neither is true: When we embrace the (very reasonable, imho) view that
  'everything is an expression', then of course statements are gone (which is good—i never quite understood
  why people have such strong felings about the superfluous expression/statement dichotomy). Now when
  statements are gone, gone are the special rights-of-way they used to enjoy. Consider these Python
  snippets::

    ###PYTHON###

    import foo

    k = 12

    if a > b or a > c:
      ...

    def x( d, e = 42 ):
      return d + e

    del x[ 10 ]

    assert u > v, "expected u > v, but that's not true; got u: {} and v: {}".format( u, v )

  In each case, statements do something you couldn't do with an expression in Python; for example,  the
  ``import`` and the ``def`` statement as wel as the assignment do accept unquoted names that might be
  undefined at that point in time—you can't have an unknown identifier in an expression, because that leads
  to ``NameError`` getting thrown.

  Also, both the ``if`` clause and the ``assert`` statement feature 'late' or 'lazy' evaluation, so ``a >
  c`` is *not* evaluated in case ``a > b`` is already true, because an ``or`` clause is already true if only
  one of its expressions is true. Similarly, the string formatting operation is only perfermed if the
  asssertions fails. Next, the ``del`` statement never looks at what value ``x[ 10 ]`` has; it just checks
  that index exists in ``x`` and then deletes that element.

  What's even more striking is how statements and operators—which in Python, they form *yet* another
  category next to expressions and statements—can and commonly do have their own syntactical rules: they
  do not need parentheses, and they (at least operators) can have an argument to their *left*, which is
  just plain unthinkable for pythonistas to allow in function calls.

  So in Python, it happens all the time: late evaluation, treatment of expression as plain text, left and
  right-hand arguments, everything. It just does not happen with expressions.

  In $LSD, everything is an expression, so by necessity, expressions must get more syntactic power. If we
  look again at this thing::

    b::   helo $name      # ...

  and at its level zero version::

    :: , b helo $ name      # ...

  we can immediately identify the things that violate some basic assumptions made in $LSD: for one, ``helo``
  should be a function (which it most probably is not); also, for ``$ name`` to make sense, ``name`` must be
  defined (text) variable, and ``$`` must only catch the *first* of its arguments and not the rest of the
  line; then, ``::`` must treat its first argument as text that spells out a variable name and understand
  the rest of the line (after the comma) as ; lastly, ``#`` must, similar to ``::``, understand its
  arguments as text and not evaluate them.

  And this is where precedence comes into the play: with precedences, we can model what should occur when.
  We still need more tools to make things like lazy evaluation happen, but with precedences we can already
  steer which functions will get which arguments to see.

  A precedence level is a classical index (a non-negative integer); each function that gets defined also
  gets a precedence level. We can pictorially explain how levels of precedence help to define orders of
  evaluation in an expression. Assume that the assignment operation has a level of 1 (just an arbitrary
  number here), and the ``#`` function has a level of 2::

                          ╭───────────
     ╭────────────────────│
     │                    │
    b::   helo $name      # ...

  When we parse this expression, what happens is that we get to see that a high-precedence function, ``#``,
  gets called to the right of a low-precedence function. And whenever that happens, a new vow in the
  rules of evaluation becomes effective::

    If a function ``g`` appears to the right of a function ``f``, the comparison of their respective
    precedences, ``Π f`` and ``Π g`` can lead to two interpretations:

    * if ``Π f ≥ Π g``, then the fundamental rules of evaluation remain unchallenged::

        ╭───────────────────
        │          ╭────────
        │          │
        │          │
        f u, v, w, g x, y, z

      xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

    * if ``Π f < Π g``, then ``g`` is

                   ╭────────
        ╭──────────│
        │          │
        f u, v, w, g x, y, z

                         ╭───────────
    ╭────────────────────│
    │                    │
    b::   helo $name      # ...






    $name: 42
    : $ name 42

    f x, y, z, g 4, 5
    f , x , y , z g , 4 5



  In all these






  """

#-----------------------------------------------------------------------------------------------------------
$.new = ->
  R =
    '~isa':                 'FLOW/PR/registry'
    '%level-by-idx':        [[]]
    'precedence-by-name':   {}
  return R

#-----------------------------------------------------------------------------------------------------------
$.validate_isa_pr_registry = ( x ) ->
  validate_argument_count_equals  1
  validate_isa x, 'PR/registry'

#-----------------------------------------------------------------------------------------------------------
$.isa_new_name = ( me, x ) ->
  validate_argument_count_equals  2
  $.validate_isa_pr_registry      me
  validate_isa_word               x
  return _.isa_new_name me, x

#...........................................................................................................
_.isa_new_name = ( me, x ) ->
  return not has me[ 'precedence-by-name' ], x

#-----------------------------------------------------------------------------------------------------------
$.isa_known_name = ( me, x ) ->
  return not $.isa_new_name me, x

#...........................................................................................................
_.isa_known_name = ( me, x ) ->
  return not _.isa_new_name me, x

#-----------------------------------------------------------------------------------------------------------
$.has = $.isa_new_name

#-----------------------------------------------------------------------------------------------------------
$.validate_isa_new_name = ( me, x ) ->
  validate_argument_count_equals  2
  unless $.isa_new_name me, x
    bye "expected a new name, but this one is not new to me: #{rpr x}"

#-----------------------------------------------------------------------------------------------------------
$.validate_isa_known_name = ( me, x ) ->
  validate_argument_count_equals  2
  unless $.isa_known_name me, x
    bye "expected a known name, but this one is not registered: #{rpr x}"

#-----------------------------------------------------------------------------------------------------------
$.validate_isa_idx_of = ( me, x ) ->
  validate_argument_count_equals    2
  validate_isa_nonnegative_integer  x
  unless x < length_of me
    bye "expected an index between 0 and #{last_key_of x}, got #{rpr x}"

#-----------------------------------------------------------------------------------------------------------
$.register_name = ( me, name ) ->
  validate_argument_count_equals  2
  $.validate_isa_pr_registry      me
  $.validate_isa_new_name         me, name
  return _.register_name me, name

#...........................................................................................................
_.register_name = ( me, name ) ->
  push me[ '%level-by-idx' ][ 0 ], name
  me[ 'precedence-by-name' ] = 0
  return me

#-----------------------------------------------------------------------------------------------------------
validate_names = TAINT.MISNAMED """``validate_names`` is a very unspecific name for what is done here""",
( me, name, known_name ) ->
  validate_argument_count_equals  3
  $.validate_isa_pr_registry      me
  validate_isa_word               name
  $.validate_isa_known_name       me, known_name

#-----------------------------------------------------------------------------------------------------------
$.place_above   = ( me, name, known_name ) -> return  place_delta me, name, known_name, +1
_.place_above   = ( me, name, known_name ) -> return _place_delta me, name, known_name, +1
#...........................................................................................................
$.place_with    = ( me, name, known_name ) -> return  place_delta me, name, known_name,  0
_.place_with    = ( me, name, known_name ) -> return _place_delta me, name, known_name,  0
#...........................................................................................................
$.place_below   = ( me, name, known_name ) -> return  place_delta me, name, known_name, -1
_.place_below   = ( me, name, known_name ) -> return _place_delta me, name, known_name, -1

#-----------------------------------------------------------------------------------------------------------
place_delta = ( me, name, known_name, delta ) ->
  validate_argument_count_equals  4
  validate_names                  me, name, known_name
  return _place_delta me, name, known_name, delta

#...........................................................................................................
_place_delta = ( me, name, known_name, delta ) ->
  validate_isa_integer            delta
  level_idx = me[ 'precedence-by-name' ][ known_name ]
  return $.place_on_level me, name, level_idx + delta

#-----------------------------------------------------------------------------------------------------------
$.place_on_level = ( me, name, level_idx ) ->
  log green [name, level_idx]
  validate_argument_count_equals  3
  $.validate_isa_pr_registry      me
  validate_isa_word               name
  validate_isa_integer            level_idx
  return _.place_on_level me, name, level_idx

#...........................................................................................................
_.place_on_level = ( me, name, level_idx ) ->
  precedences         = me[ 'precedence-by-name' ]
  levels              = me[ '%level-by-idx' ]
  old_level_idx       = precedences[ name ]
  name_is_known       = old_level_idx?
  level_count         = LIST.length_of levels
  level_with_deletion = null
  #.........................................................................................................
  unless -1 <= level_idx <= level_count
    bye "currently acceptable levels are between -1 and #{level_count}; got #{level_idx}"
  #.........................................................................................................
  if level_idx == level_count
    push levels, []
  #.........................................................................................................
  else if level_idx == -1
    old_level_idx  += 1 if old_level_idx?
    level_idx      += 1
    insert levels, []
    for _name of precedences
      precedences[ _name ] += 1
  #.........................................................................................................
  if name_is_known
    return me if old_level_idx == level_idx
    level_with_deletion = levels[ old_level_idx ]
    delete_value level_with_deletion, name
  #.........................................................................................................
  push levels[ level_idx ], name
  precedences[ name ] = level_idx
  #.........................................................................................................
  if level_with_deletion? and is_empty level_with_deletion
    LIST.delete_key levels, old_level_idx
    for _name, _level_idx of precedences
      precedences[ _name ] -= 1 if precedences[ _name ] > old_level_idx
  #.........................................................................................................
  return me

#-----------------------------------------------------------------------------------------------------------
$.length_of = ( me ) ->
  validate_argument_count_equals  1
  $.validate_isa_pr_registry      me
  return _.length_of me

#...........................................................................................................
_.length_of = ( me ) ->
  return LIST.length_of me[ '%level-by-idx' ]

#-----------------------------------------------------------------------------------------------------------
$.first_idx_of = ( me ) ->
  validate_argument_count_equals  1
  $.validate_isa_pr_registry      me
  return _.first_idx_of me

#...........................................................................................................
_.first_idx_of = ( me ) ->
  return 0

#-----------------------------------------------------------------------------------------------------------
$.last_idx_of = ( me ) ->
  validate_argument_count_equals  1
  $.validate_isa_pr_registry      me
  return _.last_idx_of me

#...........................................................................................................
_.last_idx_of = ( me ) ->
  return LIST.last_idx_of me[ '%level-by-idx' ]

#-----------------------------------------------------------------------------------------------------------
$.push = ( me, name ) ->
  validate_argument_count_equals  2
  $.validate_isa_pr_registry      me
  $.validate_isa_new_name         me, name
  return _.push me, name

#...........................................................................................................
_.push = ( me, name ) ->
  return _.place_on_level me, name, $.length_of me

#-----------------------------------------------------------------------------------------------------------
$.insert = ( me, name ) ->
  validate_argument_count_equals  2
  $.validate_isa_pr_registry      me
  $.validate_isa_new_name         me, name
  return _.insert me, name

#...........................................................................................................
_.insert = ( me, name ) ->
  return _.place_on_level me, name, -1

#-----------------------------------------------------------------------------------------------------------
$.level_of = ( me, name ) ->
  validate_argument_count_equals  2
  $.validate_isa_pr_registry      me
  $.validate_isa_known_name       me, name
  return _.level_of me, name

#...........................................................................................................
_.level_of = ( me, name ) ->
  return me[ 'precedence-by-name' ][ name ]

#-----------------------------------------------------------------------------------------------------------
$.get = ( me, idx ) ->
  validate_argument_count_equals  2
  $.validate_isa_pr_registry      me
  $.validate_isa_idx_of           me, idx
  return _.get me, idx

#...........................................................................................................
_.get = ( me, idx ) ->
  return me[ '%level-by-idx' ][ idx ]

#-----------------------------------------------------------------------------------------------------------
$.as_text = ( me ) ->
  validate_argument_count_equals  1
  $.validate_isa_pr_registry      me
  return _.as_text me

#...........................................................................................................
_.as_text = ( me ) ->
  R           = [ '', ]
  push        = LIST.push
  flush_right = TYPO.flush_right
  #.........................................................................................................
  for idx in [ ( $.last_idx_of me ) .. 0 ] by -1
    push R, "#{flush_right ( rpr idx ), 3}: #{join_commaspace _.get me, idx}"
  #.........................................................................................................
  return join_lines R


pr = PR.new()
PR.place_on_level pr, 'foo', 0
PR.place_on_level pr, 'foo', 1
# log pr[ 'precedence-by-name' ]
# log truth has pr[ 'precedence-by-name' ], 'foo'
# log truth has pr[ 'precedence-by-name' ], 'bar'
PR.place_below    pr, 'bar', 'foo'
PR.push           pr, 'last'
PR.insert         pr, 'first'
PR.place_with     pr, 'new', 'bar'
PR.place_on_level pr, 'baz', PR.level_of pr, 'bar'
PR.place_below    pr, 'new', 'foo'
log pr
log yellow $.as_text pr

############################################################################################################
[$, _] = [_$, __]

#-----------------------------------------------------------------------------------------------------------
parse = ( source ) ->
  sigils          = '@-:$%^°?+,;'
  x_sigils        = REGEX.escape sigils
  token_splitter  = new_regex "([#{x_sigils}]*)?([^#{x_sigils}]+)?([#{x_sigils}]*)?"
  for line in lines_of source
    raw_tokens = split line, new_regex '( +)'
    if ( not is_empty raw_tokens ) and ( is_empty first_of raw_tokens ) then pull raw_tokens
    log yellow join raw_tokens, '│'
    #.......................................................................................................
    for raw_token in raw_tokens
      matching_parts  = raw_token.match token_splitter
      matching_parts  = pull ( ( if isa_text match then match else null ) for match in matching_parts )
      [ prefix
        root
        suffix ] = matching_parts
      log ( red [ prefix
      root
      suffix ] )
      #, yellow [ prefix
        # root
        # suffix ] )
      #log raw_token.match new_regex '(.*?)?([^:]+)(.*)?'


ϕ = ( P... ) ->
  log yellow P
  f = last_of P
  validate_isa_function f
  stack = ( new Error() ).stack
  log stack
  R = ->
    log P
    return f.apply @, arguments

ϕ[ '~about' ] = """

  ``ϕ`` is the universal function wrapper, an important ingredient in the $LSD infrastructure.

  * Signals

  * Callbacks (?)

  * Documentation

  * Named functions. Yay!

  * Source locator with line number. Yay!




"""

g = ϕ """this is the documentation""",
  'quick':  yes
  'foo':    yes
  ( x, y, z ) ->
    return x * y * z

log g 3, 4, 5



############################################################################################################

# parse """
#   f: ( x, y ) ->
#     log :::helo world
#     @a::: 42 is the solution.

#   f 23, 42
#     """

# a = [1,2,3]
# delete_value a, 2
# log a
# log length_of a

