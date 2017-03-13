
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
# Xregex                    = require 'xregexp'
# Xregex.install 'astral'


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

# debug sepia   '#####', 'sepia'
# debug plum    '#####', 'plum'
# debug orange  '#####', 'orange'
# debug olive   '#####', 'olive'
# debug indigo  '#####', 'indigo'
# debug crimson '#####', 'crimson'
# debug brown   '#####', 'brown'
# debug lime    '#####', 'lime'
# debug steel   '#####', 'steel'


ucc_of = ( chr ) ->
  ucc = UPROPS.getCategory chr.codePointAt 0
  # return [ ucc[ 0 ], ucc[ 1 .. ], ]
  return ucc[ 0 ]

thin_out  = ( list ) -> ( x for x in list when x isnt '' )
shorten   = ( text ) -> if text.length < 2 then text else text[ 1 ... text.length - 1 ]
chrrpr    = ( text ) -> if ( /^\s+$/.test text ) then ( CND.reverse shorten rpr text ) else text
flag      = yes
toggle    = -> flag = not flag
get_color = ( c1, c2 ) -> ( x ) -> if toggle() then c1 x else c2 x
color     = get_color steel, orange
rainbow   = ( list ) -> ( ( color chrrpr x ) for x in list ).join ''
join      = ( list ) -> list.join '_'
### TAINT pluck for lists looks different ###
pluck     = ( x, key ) -> R = x[ key ]; delete x[ key ]; return R





PS                        = require 'pipestreams'
{ $, map, }               = PS
{ step, }                 = require 'coffeenode-suspend'


#-----------------------------------------------------------------------------------------------------------
FM = {}

f = ->
  #===========================================================================================================
  # LEX/prepare
  #-----------------------------------------------------------------------------------------------------------
  @$prepare = ->
    pipeline = []
    pipeline.push @$prepare.$as_lines()         # LEX/prepare/as-lines
    pipeline.push @$prepare.$as_line_events()   # LEX/prepare/as-line-events
    pipeline.push @$prepare.$add_positions()    # LEX/prepare/add-positions
    pipeline.push @$prepare.$add_chunks()       # LEX/prepare/add-positions
    pipeline.push @$prepare.$recognize_fncrs()
    pipeline.push @$prepare.$recognize_ncrs()
    pipeline.push @$prepare.$splice_ncrs()
    pipeline.push @$prepare.$as_chrs()          # LEX/prepare/as-chrs
    return PS.pull pipeline...

  #-----------------------------------------------------------------------------------------------------------
  @$prepare.$as_lines = =>
    ### Only recognizes `\n` (as it should). In the sequences `\r`, `\r\n`, `\n\r`, `\u2028`, `\u2029`, only
    `\n` (U+000a) causes a new line, and all other codepoints are preserved. ###
    return PS.$split()

  #-----------------------------------------------------------------------------------------------------------
  @$prepare.$as_line_events = =>
    ### TAINT assuming all lines are terminated with `\n` ###
    return PS.map ( image ) =>
      ### TAINT technically, not a chunk (?) ###
      return FM.U.new_chunk { type: 'line', image, }

  #-----------------------------------------------------------------------------------------------------------
  @$prepare.$add_positions = =>
    y   = -1
    x   = 0
    xx  = 0
    return PS.map ( event ) ->
      { image, }      = event
      y        += +1
      ### `+ 1` to account for newline that has been omitted ###
      xx        = x + image.length + 1
      event.y   = y
      event.x   = x
      event.xx  = xx
      x         = xx
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$prepare.$add_chunks = =>
    ### TAINT assuming all lines are terminated with `\n` ###
    return PS.map ( event ) ->
      return event unless event.type is 'line'
      ### TAINT *must* be able at this point to distinguish lines with and without newline ###
      # position.xx  += -1 # adjust for missing newline
      chunk           = FM.U.new_chunk event
      chunk.type      = 'chrs'
      event.chunks    = [ chunk, ]
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$prepare.$recognize_fncrs = ->
    # pattern = /// ( &\# x ) ( [ 0-9 a-f ]{1,6} ) ( ; ) ///g
    pattern = /// ( [ - 0-9 a-z ]+ [ \/ - ] [ 0-9 a-f ]+ ) ///g
    return PS.map ( event ) ->
      return event unless event.type is 'line'
      #.......................................................................................................
      source_chunks = event.chunks
      target_chunks = event.chunks = []
      #.......................................................................................................
      for source_chunk in source_chunks
        #.....................................................................................................
        unless source_chunk.type is 'chrs'
          target_chunks.push source_chunk
          continue
        #.....................................................................................................
        { image, y, x, }  = source_chunk
        is_plain          = no
        xx                = x
        for part in image.split pattern
          is_plain  = not is_plain
          xx       += part.length
          if is_plain
            target_chunks.push FM.U.new_chunk { type: 'chrs', y, x, xx, image: part, }
            x = xx
            continue
          target_chunks.push FM.U.new_chunk { type: 'fncr', y, x, xx, image: part, }
          x = xx
      #.......................................................................................................
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$prepare.$recognize_ncrs = ->
    # pattern = /// ( &\# x ) ( [ 0-9 a-f ]{1,6} ) ( ; ) ///g
    pattern = /// ( &\# x     [ 0-9 a-f ]{1,6}     ; ) ///g
    return PS.map ( event ) ->
      return event unless event.type is 'line'
      #.......................................................................................................
      source_chunks = event.chunks
      target_chunks = event.chunks = []
      #.......................................................................................................
      for source_chunk in source_chunks
        #.....................................................................................................
        unless source_chunk.type is 'chrs'
          target_chunks.push source_chunk
          continue
        #.....................................................................................................
        { image, y, x, }  = source_chunk
        is_plain          = no
        xx                = x
        for part in image.split pattern
          is_plain  = not is_plain
          xx       += part.length
          if is_plain
            target_chunks.push FM.U.new_chunk { type: 'chrs', y, x, xx, image: part, }
            x = xx
            continue
          cid     = parseInt part[ 3 ... part.length - 1 ], 16
          target  = String.fromCodePoint cid
          target_chunks.push FM.U.new_chunk { type: 'ncr', y, x, xx, image: part, cid, target, }
          x = xx
      #.......................................................................................................
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$prepare.$splice_ncrs = ->
    return PS.map ( event ) ->
      return event unless event.type is 'line'
      for chunk, idx in event.chunks
        continue unless chunk.type is 'ncr'
        event.chunks[ idx ] = chunk = FM.U.new_chunk chunk
        delete chunk.cid
        chunk.type = 'chr'
      #.......................................................................................................
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$prepare.$as_chrs = =>
    return PS.map ( event ) ->
      source_chunks = event.chunks
      target_chunks = event.chunks = []
      for source_chunk in source_chunks
        unless source_chunk.type is 'chrs'
          target_chunks.push source_chunk
          continue
        { y, x, } = source_chunk
        for chr in Array.from source_chunk.image
          xx            = x + chr.length
          target_chunk  = FM.U.new_chunk { type: 'chr', y, x, xx, image: chr, }
          x             = xx
          target_chunks.push target_chunk
      return event


  #===========================================================================================================
  #
  #-----------------------------------------------------------------------------------------------------------
  @$group_chrs_by_ucc = ->
    pipeline = []
    pipeline.push @$group_chrs_by_ucc.$add_uccs()
    pipeline.push @$group_chrs_by_ucc.$rewrite_lws()
    # pipeline.push PS.$show title: '368723'
    pipeline.push @$group_chrs_by_ucc.$group_by_ucc()
    return PS.pull pipeline...

  #-----------------------------------------------------------------------------------------------------------
  @$group_chrs_by_ucc.$add_uccs = =>
    return PS.map ( event ) ->
      return event unless event.type is 'line'
      for chunk in event.chunks
        continue unless chunk.type is 'chr'
        chunk.ucc = ucc_of chunk.target
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$group_chrs_by_ucc.$rewrite_lws = ->
    return PS.map ( event ) ->
      return event unless event.type is 'line'
      for chunk, idx in event.chunks
        continue unless chunk.type    is 'chr'
        continue unless chunk.target  is '\u0020'
        event.chunks[ idx ] = chunk = FM.U.new_chunk chunk, { ucc: 'lws', }
        # delete chunk.subucc
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$group_chrs_by_ucc.$group_by_ucc = ->
    ### TAINT could / should be optimized to use collector list, then concatenate all chunks at once ###
    #.........................................................................................................
    return PS.map ( event ) ->
      return event unless event.type is 'line'
      source_chunks     = event.chunks
      target_chunks     = event.chunks = []
      target_chunk      = null
      prv_ucc           = null
      #.......................................................................................................
      flush = ->
        target_chunks.push target_chunk if target_chunk?
        target_chunk  = null
        prv_ucc       = null
      #.......................................................................................................
      for chunk in source_chunks
        unless chunk.type is 'chr'
          flush()
          target_chunks.push chunk
          continue
        { ucc, } = chunk
        if ucc is prv_ucc
          target_chunk = FM.U.merge_chunks target_chunk, chunk, { type: 'chrs', }
        else
          flush()
        target_chunk ?= FM.U.merge_chunks chunk, null, { type: 'chrs', }
        prv_ucc       = ucc
        # debug '44532', target_chunk
      #.......................................................................................................
      flush()
      return event

  #===========================================================================================================
  # LEX/identifiers
  #-----------------------------------------------------------------------------------------------------------
  @$identifiers = ->
    pipeline = []
    pipeline.push @$identifiers.$add_identifier_type()
    pipeline.push @$identifiers.$group_identifiers()
    return PS.pull pipeline...

  #-----------------------------------------------------------------------------------------------------------
  @$identifiers.$add_identifier_type = =>
    return PS.map ( event ) =>
      return event unless event.type is 'line'
      for chunk, idx in event.chunks
        continue unless ( chunk.type is 'chrs' ) and ( chunk.ucc is 'L' )
        chunk.type = 'identifier'
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$identifiers.$group_identifiers = =>
    return PS.map ( event ) =>
      return event unless event.type is 'line'
      #.......................................................................................................
      prv_type      = null
      target_chunk  = null
      source_chunks = event.chunks
      target_chunks = event.chunks = []
      #.......................................................................................................
      for chunk, idx in source_chunks
        if chunk.type is 'identifier'
          unless target_chunk?
            target_chunk  = FM.U.merge_chunks chunk
            prv_type      = chunk.type
            delete target_chunk.ucc
            continue
          target_chunk = FM.U.merge_chunks target_chunk, chunk
          continue
        if prv_type is 'identifier'
          if ( chunk.image is '-' ) or ( chunk.image is '_' ) or ( chunk.ucc is 'N' )
            target_chunk = FM.U.merge_chunks target_chunk, chunk
            continue
        target_chunks.push target_chunk if target_chunk?
        target_chunks.push chunk
        target_chunk  = null
        prv_type      = chunk.type
      #.......................................................................................................
      target_chunks.push target_chunk if target_chunk?
      return event

  #===========================================================================================================
  # LEX/finalize
  #-----------------------------------------------------------------------------------------------------------
  @$finalize = ->
    pipeline = []
    pipeline.push @$finalize.$update_line_target()
    return PS.pull pipeline...

  #-----------------------------------------------------------------------------------------------------------
  @$finalize.$update_line_target = =>
    return PS.map ( event ) =>
      return event unless event.type is 'line'
      event.target = ( chunk.target for chunk in event.chunks ).join ''
      return event


  #===========================================================================================================
  #
  #-----------------------------------------------------------------------------------------------------------
  @$lex = ->
    pipeline = []
    pipeline.push @$prepare()
    pipeline.push @$group_chrs_by_ucc()
    pipeline.push @$identifiers()
    pipeline.push @$finalize()
    # pipeline.push PS.$show()
    return PS.pull pipeline...

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

g = ->

  #-----------------------------------------------------------------------------------------------------------
  @new_chunk = ( P... ) ->
    R         = Object.assign {}, P...
    R.target ?= R.image
    return R

  #-----------------------------------------------------------------------------------------------------------
  @merge_chunks = ( a, b, P... ) ->
    R = FM.U.new_chunk a, P...
    return R unless b?
    unless a.y is b.y
      throw new Error "can't merge chunks from different lines: #{rpr a}, #{rpr b}"
    unless a.x <= b.x
      throw new Error "MEH #1"
    unless a.xx is b.x
      throw new Error "MEH #2"
    # unless a.ucc is b.ucc
    #   throw new Error "MEH #3"
    R.xx      = b.xx
    R.image   = R.image   + b.image
    R.target  = R.target  + b.target
    return R

FM = {}
f.apply FM.LEXER  = {}
g.apply FM.U      = {}


#-----------------------------------------------------------------------------------------------------------
TAP.test "basic model", ( T ) ->
  debug '-----------------------------------------------'
  debug "basic model"
  debug '-----------------------------------------------'
  # Randex  = require 'randexp'
  # randex  = new Randex /[-\x20a-z0-9\/()\[\]§$%^°+*´`=?]{0,150}/
  probes_and_matchers = [
    # [ 'ab++c23\nd"axyzd\t++dy',   'ab_++_c_23_\n_d_"_a_xyz_d_\t_++_d_y', ]
    # [ 'ab++c23\nd"xyzd\t++dy',  'ab_++_c_23_\n_d_"_xyz_d_\t_++_d_y', ]
    [ 'y = x ** 2 for x in [ 1, 2, 3, ]','']
    # [ '12ab','']
    [ '123abc$%\n2\n3\n456 xyz\n\n','']
    # [ '1\n#','']
    # [ '2\r#','']
    # [ '3\r\n#','']
    # [ '4\n\r#','']
    # [ '5\u2028#','']
    # [ '6\u2029#','']
    # [ 'u-cjk-xb/22f33 𢼳 ⿰匡夊','']
    [ 'a&#x64;z','']
    [ 'a&#x21;z','']
    [ 'a&#x21;bc&#x22;de','']
    [ 'u-cjk-xb/22f33 &#x22f33; ⿰匡夊','']
    [ 'my-sum = ( foo-knows + bar42 ) * under_score','']
    ]
  thin_out  = ( list ) -> ( x for x in list when x isnt '' )
  join      = ( list ) -> list.join '_'
  self = this
  step ( resume ) ->
    for [ probe, matcher, ] in probes_and_matchers
      urge rpr probe
      lines = yield FM.LEXER.lex probe, resume
      for line in lines
        # whisper JSON.stringify line
        info line.y, rpr line.image
        # whisper rpr line.target
        whisper rainbow ( chunk.target for chunk in line.chunks )
        help '  ' + JSON.stringify chunk for chunk in line.chunks
      # result  = join thin_out probe.split splitter
      # debug thin_out probe.split splitter
      # whisper rpr result
      # whisper rpr matcher
      # T.ok result is matcher
    T.end()
    return null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "stress test", ( T ) ->
  path = PATH.resolve __dirname, '../../../mingkwai-rack/jizura-datasources/data/flat-files/shape/shape-breakdown-formula.txt'
  pipeline = []
  pipeline.push input   = PS.new_file_source path
  pipeline.push FM.LEXER.$lex()
  # pipeline.push PS.$show()
  pipeline.push do ->
    count = 0
    return PS.map ( data ) ->
      help count if ( count += +1 ) % 1e4 is 0
      return data
  pipeline.push PS.map ( event ) -> event.target + '\n'
  # pipeline.push PS.map ( data ) -> ( JSON.stringify data ) + '\n'
  pipeline.push output  = PS.new_file_sink '/tmp/x'
  # pipeline.push PS.$drain()
  output.on 'finish', -> T.end()
  PS.pull pipeline...



