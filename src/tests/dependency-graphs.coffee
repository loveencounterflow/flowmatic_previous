
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

