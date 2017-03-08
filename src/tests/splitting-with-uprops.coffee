
'use strict'

###
* https://github.com/devongovett/unicode-trie
* https://github.com/devongovett/unicode-properties

  When implementing many Unicode algorithms such as text segmentation, normalization, bidi processing, etc.,
  fast access to character metadata is crucial to good performance. There over a million code points in the
  Unicode standard, many of which produce the same result when looked up, so an array or hash table is not
  appropriate - those data structures are fast but would require a lot of memory. The data is generally
  grouped in ranges, so you could do a binary search, but that is not fast enough for some applications.

  The International Components for Unicode (ICU) project came up with a data structure based on a Trie that
  provides fast access to Unicode metadata. The range data is precompiled to a serialized and flattened
  trie, which is then used at runtime to lookup the necessary data. According to my own tests, this is
  generally at least 50% faster than binary search, with not too much additional memory required.


* https://github.com/mathiasbynens/regenerate-unicode-properties


for reference:
* (https://github.com/mathiasbynens/regenerate)
* (https://github.com/mathiasbynens/unicode-8.0.0)
* (https://github.com/mathiasbynens/node-unicode-data)
* ncr


###


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'FLOWMATIC/TESTS/BASIC'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
UPROPS                    = require 'unicode-properties'
#...........................................................................................................
TAP                       = require 'tap'
Xregex                    = require 'xregexp'
Xregex.install 'astral'
{ sepia
  plum
  pink
  orange
  olive
  indigo
  crimson
  brown
  lime
  steel } = CND

debug sepia   '#####', 'sepia'
debug plum    '#####', 'plum'
debug orange  '#####', 'orange'
debug olive   '#####', 'olive'
debug indigo  '#####', 'indigo'
debug crimson '#####', 'crimson'
debug brown   '#####', 'brown'
debug lime    '#####', 'lime'
debug steel   '#####', 'steel'



categories = [
  { name: 'C',   alias: 'Other',                   }
  { name: 'L',   alias: 'Letter',                  }
  { name: 'M',   alias: 'Mark',                    }
  { name: 'N',   alias: 'Number',                  }
  { name: 'P',   alias: 'Punctuation',             }
  { name: 'S',   alias: 'Symbol',                  }
  { name: 'Z',   alias: 'Separator',               }
  ]

sub_categories = [
  { name: 'Cc',  alias: 'Control',                 }
  { name: 'Cf',  alias: 'Format',                  }
  { name: 'Cn',  alias: 'Unassigned',              }
  { name: 'Co',  alias: 'Private_Use',             }
  { name: 'Cs',  alias: 'Surrogate',               }
  { name: 'Ll',  alias: 'Lowercase_Letter',        }
  { name: 'Lm',  alias: 'Modifier_Letter',         }
  { name: 'Lo',  alias: 'Other_Letter',            }
  { name: 'Lt',  alias: 'Titlecase_Letter',        }
  { name: 'Lu',  alias: 'Uppercase_Letter',        }
  { name: 'Mc',  alias: 'Spacing_Mark',            }
  { name: 'Me',  alias: 'Enclosing_Mark',          }
  { name: 'Mn',  alias: 'Nonspacing_Mark',         }
  { name: 'Nd',  alias: 'Decimal_Number',          }
  { name: 'Nl',  alias: 'Letter_Number',           }
  { name: 'No',  alias: 'Other_Number',            }
  { name: 'Pc',  alias: 'Connector_Punctuation',   }
  { name: 'Pd',  alias: 'Dash_Punctuation',        }
  { name: 'Pe',  alias: 'Close_Punctuation',       }
  { name: 'Pf',  alias: 'Final_Punctuation',       }
  { name: 'Pi',  alias: 'Initial_Punctuation',     }
  { name: 'Po',  alias: 'Other_Punctuation',       }
  { name: 'Ps',  alias: 'Open_Punctuation',        }
  { name: 'Sc',  alias: 'Currency_Symbol',         }
  { name: 'Sk',  alias: 'Modifier_Symbol',         }
  { name: 'Sm',  alias: 'Math_Symbol',             }
  { name: 'So',  alias: 'Other_Symbol',            }
  { name: 'Zl',  alias: 'Line_Separator',          }
  { name: 'Zp',  alias: 'Paragraph_Separator',     }
  { name: 'Zs',  alias: 'Space_Separator',         }
  ]

ucc_of    = ( chr ) -> ( UPROPS.getCategory chr.codePointAt 0 )[ 0 ]
thin_out  = ( list ) -> ( x for x in list when x isnt '' )
shorten   = ( text ) -> if text.length < 2 then text else text[ 1 ... text.length - 1 ]
chrrpr    = ( text ) -> if ( /^\s+$/.test text ) then ( CND.reverse shorten rpr text ) else text
flag      = yes
toggle    = -> flag = not flag
get_color = ( c1, c2 ) -> ( x ) -> if toggle() then c1 x else c2 x
color     = get_color steel, orange
rainbow   = ( list ) -> ( ( color chrrpr x ) for x in list ).join ''
join      = ( list ) -> list.join '_'

PS                        = require 'pipestreams'
{ $, map, }               = PS
{ step, }                 = require 'coffeenode-suspend'



f = ->
  #-----------------------------------------------------------------------------------------------------------
  @$lex = ->
    pipeline = []
    pipeline.push @$as_lines()
    pipeline.push @$as_characters()
    pipeline.push @$add_uccs()
    pipeline.push @$rewrite_lws()
    pipeline.push @$group_by_ucc()
    pipeline.push @$join_groups()
    return PS.pull pipeline...

  #-----------------------------------------------------------------------------------------------------------
  @$as_lines      = -> PS.$split()
  @$as_characters = -> PS.map ( line ) -> Array.from line
  @$add_uccs      = -> PS.map ( chrs ) -> ( [ chr, ucc_of chr ] for chr in chrs )

  #-----------------------------------------------------------------------------------------------------------
  @$rewrite_lws = -> PS.map ( chrs_and_uccs ) ->
    return ( [ chr, ( if chr is '\x20' then 'lws' else ucc ) ] for [ chr, ucc, ] in chrs_and_uccs )

  #-----------------------------------------------------------------------------------------------------------
  @$join_groups = -> PS.map ( event ) ->
    chunk.chrs = chunk.chrs.join '' for chunk in event.chunks
    return event

  #-----------------------------------------------------------------------------------------------------------
  @$group_by_ucc = ->
    return $ ( chrs_and_uccs, send ) ->
      prv_ucc   = null
      chrs      = null
      chunk     = null
      chunks    = []
      event     = { type: 'line', chunks, }
      #.......................................................................................................
      for [ chr, ucc, ] in chrs_and_uccs
        if ucc isnt prv_ucc
          if chunk?
            chunks.push chunk
          chrs    = []
          chunk   = { ucc, chrs, }
          prv_ucc = ucc
        chrs.push chr
      chunks.push chunk if chunk?
      #.......................................................................................................
      send event
      return null

  #-----------------------------------------------------------------------------------------------------------
  @lex = ( text, handler ) ->
    pipeline  = []
    Z         = []
    pipeline.push PS.new_text_source text
    pipeline.push @$lex()
    pipeline.push $ 'null', ( event, send ) ->
      if event?
        Z.push event
        send event
      else
        handler null, Z
      return null
    pipeline.push PS.$drain()
    return PS.pull pipeline...

FM = {}
f.apply FM.LEXER = {}

###

#-----------------------------------------------------------------------------------------------------------
TAP.test "basic model", ( T ) ->
  debug '-----------------------------------------------'
  debug "basic model"
  debug '-----------------------------------------------'
  # Randex  = require 'randexp'
  # randex  = new Randex /[-\x20a-z0-9\/()\[\]§$%^°+*´`=?]{0,150}/
  probes_and_matchers = [
    [ 'ab++c23\nd"axyzd\t++dy',   'ab_++_c_23_\n_d_"_a_xyz_d_\t_++_d_y', ]
    [ 'ab++c23\nd"xyzd\t++dy',  'ab_++_c_23_\n_d_"_xyz_d_\t_++_d_y', ]
    [ 'u-cjk-xb/22f33 𢼳 ⿰匡夊','']
    [ 'y = x ** 2 for x in [ 1, 2, 3, ]','']
    ]
  thin_out  = ( list ) -> ( x for x in list when x isnt '' )
  join      = ( list ) -> list.join '_'
  self = this
  step ( resume ) ->
    for [ probe, matcher, ] in probes_and_matchers
      urge rpr probe
      urge yield FM.LEXER.lex probe, resume
      # result  = join thin_out probe.split splitter
      # debug thin_out probe.split splitter
      # whisper rpr result
      # whisper rpr matcher
      # T.ok result is matcher
    T.end()
    return null
  #.........................................................................................................
  return null

###

FM[ 'has-transforms' ] = yes
FM.LEXER[ 'has-transforms' ] = yes

@walk_transforms = ( root, prefix = null ) -> @_walk_transforms root, prefix, {}

@_walk_transforms = ( root, prefix = null, R ) ->
  if prefix?
    prefix = [ prefix, ] unless CND.isa_list prefix
  else
    prefix = []
  for name, descriptor of Object.getOwnPropertyDescriptors root
    { value: method, } = descriptor
    switch type = CND.type_of method
      when 'pod'
        continue unless method[ 'has-transforms' ]
        prefix.push name
        return @_walk_transforms method, prefix, R
        prefix.pop()
      when 'function'
        continue unless name.startsWith '$'
        key               = name[ 1 .. ].replace /_/g, '-'
        path              = PATH.join prefix..., key
        { description, }  = method
        description      ?= {}
        R[ path ]         = { method, description, }
  return R

debug '89883', @walk_transforms FM, 'FM'
debug '89883', FM
# debug '89883', FM.LEXER.$lex.name


LTSORT = require 'ltsort'

f = ->
  #-----------------------------------------------------------------------------------------------------------
  @new_graph = ( prefix ) ->
    R               = LTSORT.new_graph loners: no
    ### TAINT use library-specific symbol ###
    R[ '%prefix' ]        = prefix ? ''
    R[ '%attachments' ]   = {}
    return R

  #-----------------------------------------------------------------------------------------------------------
  @attach = ( me, need, key ) ->
    need    = @_resolve_path me, need
    ref     = @_resolve_path me, key
    target  = me[ '%attachments' ][ need ] ?= []
    target.push key
    return null

  #-----------------------------------------------------------------------------------------------------------
  @_resolve_path = ( me, key ) ->
    prefix  = me[ '%prefix' ]
    R = PATH.resolve  '/', me[ '%prefix' ], key
    R = PATH.relative '/', R if not PATH.isAbsolute prefix
    return R

  #-----------------------------------------------------------------------------------------------------------
  @add = ( me, key, description ) ->
    # name              = '$' + key.replace /-/g, '_'
    needs   = null
    feeds   = null
    if description?
      { needs, feeds, } = description
    needs  ?= []
    feeds  ?= []
    needs   = @_pluralize null, needs
    feeds   = @_pluralize null, feeds
    needs   = ( @_resolve_path me, need for need in needs )
    feeds   = ( @_resolve_path me, feed for feed in feeds )
    ref     = @_resolve_path me, key
    # @_add_ancestry me, ref
    # @_add_ancestry me, needs
    # @_add_ancestry me, feeds
    @_add_start_and_stop me, ref
    @_add_start_and_stop me, needs
    @_add_start_and_stop me, feeds
    LTSORT.add me, precedent,  ref             for precedent   in needs
    LTSORT.add me,             ref, consequent for consequent  in feeds
    return null

  #-----------------------------------------------------------------------------------------------------------
  @_pluralize = ( _, x ) -> if ( CND.isa_list x ) then x else [ x, ]

  # #-----------------------------------------------------------------------------------------------------------
  # @_add_ancestry = ( me, path_or_paths ) ->
  #   paths     = @_pluralize null, path_or_paths
  #   # ancestors = new Set()
  #   @_add_start_and_stop me, paths
  #   for path in paths
  #     ancestors = @_get_ancestry null, path
  #     parent    = ancestors[ 0 ]
  #     if parent?
  #       parent_start  = PATH.join parent, '~START'
  #       parent_stop   = PATH.join parent, '~STOP'
  #       @_add_start_and_stop me, [ parent_start, parent_stop, ]
  #       LTSORT.add me, parent_start, path
  #       LTSORT.add me,               path, parent_stop
  #   #   for ancestor in @_get_ancestry null, path
  #   #     ancestors.add ancestor # unless LTSORT.has_node me, ancestor
  #   # ### NOTE do not iterate using `for x from set`, b/c iteration would include newly added elements ###
  #   # # for ancestor in Array.from ancestors
  #   # #   # debug '33322', PATH.join ancestor, '~START'
  #   # #   ancestors.add PATH.join ancestor, '~START'
  #   # for ancestor from ancestors
  #   #   @_add_start_and_stop me, ancestor
  #   return null

  # #-----------------------------------------------------------------------------------------------------------
  # _is_start = ( x ) -> x is '~START' or x.endsWith '/~START'
  # _is_stop  = ( x ) -> x is '~STOP'  or x.endsWith '/~STOP'

  #-----------------------------------------------------------------------------------------------------------
  @_add_start_and_stop = ( me, path_or_paths ) ->
    paths = @_pluralize null, path_or_paths
    for path in paths
      # debug '77762', [ '~START', path, ]
      # debug '77762', [ path, '~STOP', ]
      LTSORT.add me, '~START', path          unless path is '~START'
      LTSORT.add me,           path, '~STOP' unless path is '~STOP'
      # debug '88892', ( PATH.join ( PATH.dirname path ), '~START' )
      # LTSORT.add me, ( PATH.join ( PATH.dirname path ), '~START' ), path
    return null

  #-----------------------------------------------------------------------------------------------------------
  ### TAINT should honor result of `@group` method ###
  @get_linearity  = ( me, P... ) -> LTSORT.get_linearity me, P...

  #-----------------------------------------------------------------------------------------------------------
  @group = ( me, P... ) ->
    ### TAINT should only push attachments to current group when group length > 1 ###
    groups  = LTSORT.group me, P...
    R       = []
    for group in groups
      target = []
      R.push target
      for ref in group
        target.push ref
        ### TAINT code duplication ###
        continue unless ( attachments = me[ '%attachments' ][ ref ] )?
        target.push attachment for attachment in attachments
    return R

  #-----------------------------------------------------------------------------------------------------------
  @linearize = ( me, P... ) ->
    refs  = LTSORT.linearize me, P...
    R     = []
    for ref in refs
      R.push ref
      ### TAINT code duplication ###
      continue unless ( attachments = me[ '%attachments' ][ ref ] )?
      R.push attachment for attachment in attachments
    return R

  # #-----------------------------------------------------------------------------------------------------------
  # @_get_ancestry = ( _, path ) ->
  #   R = []
  #   while path not in [ '.', '/', ]
  #     ### TAINT contains one superfluous path operation ###
  #     ### TAINT assumes all libraries are written with uppercase US ASCII letters ###
  #     R.push path if /^[-A-Z]+$/.test PATH.basename path
  #     path = PATH.dirname path
  #   return R

f.apply XXX = {}

entries = [
  # [ 'LEXER/~START',         feeds: 'LEXER/~STOP',                                            ]
  # [ 'TRANSFORM/~START',     needs: 'LEXER/~STOP',           feeds: 'TRANSFORM/~STOP',        ]
  # [ 'WRITER/~START',        feeds: 'WRITER/~STOP',                                           ]
  # [ 'WRITER/~START',        needs: 'TRANSFORM/~STOP',                                        ]
  # [ 'LEXER/as-lines',       needs: 'LEXER/~START',                                           ]
  [ 'LEXER/as-lines',                                                  ]
  [ 'LEXER/as-characters',  needs: 'LEXER/as-lines',                                         ]
  [ 'LEXER/add-uccs',       needs: 'LEXER/as-characters',                                    ]
  [ 'LEXER/rewrite-lws',    needs: 'LEXER/add-uccs',        feeds:  'LEXER/group-by-ucc',    ]
  [ 'LEXER/group-by-ucc',   needs: 'LEXER/add-uccs',                                         ]
  # [ 'LEXER/join-groups',    needs: 'LEXER/group-by-ucc',    feeds: 'LEXER/~STOP',            ]
  [ 'LEXER/join-groups',    needs: 'LEXER/group-by-ucc',                ]
  ]

show = ( graph ) ->
  help key for key in XXX.linearize graph
  info group for group in XXX.group graph
  info XXX.get_linearity graph

graph = XXX.new_graph 'FM'
for [ key, description, ] in CND.shuffle entries
  XXX.add graph, key, description
# debug '88876', LTSORT.find_root_nodes graph
show graph


# urge 'as-lines'
# urge 'as-characters'
# urge 'add-uccs'
# urge 'rewrite-lws'
# urge 'group-by-ucc'
# urge 'join-groups'


XXX.attach graph, 'LEXER/rewrite-lws', '/PS/show'
show graph


#-----------------------------------------------------------------------------------------------------------
@get_linearity = ( graph ) ->
  ### Linearity of a given dependency graph measures how well the dependency relations in a graph
  determine an ordering of its nodes. For a graph that defines a unique, single chain of antecedents and
  consequents, linearity will be 1; for a graph that defines only nodes and no dependency edges, linearity
  will be zero; for all other kind of graphs, linearity will be the inverse of the average group length.
  The linearity of all graphs with a single element is 1. The linearity of the emtpy graph is also 1, since
  that is the limit that is approached taking ever more nodes out of maximally linear as well as out of
  minimally linear (parallel-only) graphs. ###
  throw new Error "linearity not implemented for graphs with loners" if graph[ 'loners' ]
  groups  = @group graph
  size    = groups.length
  return 1 if size is 0
  count   = 0
  count  += group.length for group in groups
  minimum = 1 / count
  shrink  = 1 - minimum
  return ( ( groups.length / count ) - minimum ) / shrink

graph = LTSORT.new_graph loners: no
LTSORT.add graph, 'X'
LTSORT.add graph, 'Y'
debug LTSORT.get_linearity graph; debug @get_linearity.apply LTSORT, [ graph, ]
LTSORT.add graph, 'Z'
debug LTSORT.get_linearity graph; debug @get_linearity.apply LTSORT, [ graph, ]
LTSORT.add graph, 'A', 'B'
LTSORT.add graph, 'B', 'C'
info group for group in LTSORT.group graph; debug LTSORT.get_linearity graph; debug @get_linearity.apply LTSORT, [ graph, ]
LTSORT.add graph, 'A', 'a'
info group for group in LTSORT.group graph; debug LTSORT.get_linearity graph; debug @get_linearity.apply LTSORT, [ graph, ]



