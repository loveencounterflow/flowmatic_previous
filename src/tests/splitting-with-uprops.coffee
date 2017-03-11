
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
### TAINT pluck for lists looks different ###
pluck     = ( x, key ) -> R = x[ key ]; delete x[ key ]; return R

PS                        = require 'pipestreams'
{ $, map, }               = PS
{ step, }                 = require 'coffeenode-suspend'



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
    pipeline.push @$prepare.$TEST_recognize_ncrs()
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
    return PS.map ( image ) ->
      return { type: 'line', image, }

  #-----------------------------------------------------------------------------------------------------------
  @$prepare.$add_positions = =>
    line_nr = 0
    start   = 0
    stop    = 0
    return PS.map ( event ) ->
      { image, }      = event
      line_nr        += +1
      ### `+ 1` to account for newline that has been omitted ###
      stop            = start + image.length + 1
      event.position  = { line: line_nr, start, stop, }
      start           = stop
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$prepare.$add_chunks = =>
    ### TAINT assuming all lines are terminated with `\n` ###
    return PS.map ( event ) ->
      return event unless event.type is 'line'
      position        = Object.assign {}, event.position
      ### TAINT *must* be able at this point to distinguish lines with and without newline ###
      # position.stop  += -1 # adjust for missing newline
      chunk           = Object.assign {}, event, { position, }
      chunk.type      = 'chrs'
      event.chunks    = [ chunk, ]
      debug '7739', chunk.position is event.position
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$prepare.$TEST_recognize_ncrs = ->
    # pattern = /// ( &\# x ) ( [ 0-9 a-f ]{1,6} ) ( ; ) ///g
    pattern = /// ( &\# x     [ 0-9 a-f ]{1,6}     ; ) ///g
    return PS.map ( event ) ->
      return event unless event.type is 'line'
      debug '32221', event
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
        { image, }        = source_chunk
        debug image.split pattern
        # pattern.lastIndex = 0
        #.....................................................................................................
        # while ( match = pattern.exec image )?
        #   start                 = match.index
        #   [ stretch, cid_hex, ] = match
        #   stop                  = start + stretch.length
        #   cid                   = parseInt cid_hex, 16
        #   debug '33211', ( rpr image ), match
        #   prefix                = image[ ... start               ]
        #   infix                 = image[     start ... stop      ]
        #   suffix                = image[               stop ...  ]
        #   target_chunks.push { type: 'chrs',  image: prefix } if prefix.length > 0
        #   target_chunks.push { type: 'ncr',   image: infix, cid, }
        #   target_chunks.push { type: 'chrs',  image: suffix } if suffix.length > 0
      #.......................................................................................................
      info '99982', event
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
        { line: line_nr, start, } = source_chunk.position
        for chr in Array.from source_chunk.image
          stop          = start + chr.length
          position      = { line: line_nr, start, stop, }
          target_chunk  = { type: 'chr', position, image: chr, }
          start         = stop
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
        chunk.ucc = ucc_of chunk.image
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$group_chrs_by_ucc.$rewrite_lws = ->
    return PS.map ( event ) ->
      return event unless event.type is 'line'
      for chunk in event.chunks
        continue unless chunk.type is 'chr'
        continue unless chunk.image is '\u0020'
        chunk.ucc = 'lws'
      return event

  #-----------------------------------------------------------------------------------------------------------
  @$group_chrs_by_ucc.$group_by_ucc = ->
    ### TAINT could / should be optimized to use collector list, then concatenate all chunks at once ###
    #.........................................................................................................
    merge_chunks = ( a, b ) ->
      R           = Object.assign {}, a
      R.position  = Object.assign {}, R.position
      R.type      = 'chrs'
      return R unless b?
      unless a.position.line is b.position.line
        throw new Error "can't merge chunks from different lines: #{rpr a}, #{rpr b}"
      unless a.position.start <= b.position.start
        throw new Error "MEH #1"
      unless a.position.stop is b.position.start
        throw new Error "MEH #2"
      unless a.ucc is b.ucc
        throw new Error "MEH #3"
      R.position.stop = b.position.stop
      R.image         = R.image + b.image
      return R
    #.........................................................................................................
    return PS.map ( event ) ->
      return event unless event.type is 'line'
      source_chunks     = event.chunks
      target_chunks     = event.chunks = []
      target_chunk      = null
      #.......................................................................................................
      for chunk in source_chunks
        unless chunk.type is 'chr'
          target_chunks.push chunk
          continue
        { ucc, } = chunk
        if ucc is prv_ucc
          target_chunk = merge_chunks target_chunk, chunk
        else
          if target_chunk?
            target_chunks.push target_chunk
            target_chunk = null
        target_chunk ?= merge_chunks chunk
        prv_ucc       = ucc
        # debug '44532', target_chunk
      #.......................................................................................................
      target_chunks.push target_chunk if target_chunk?
      return event

  #===========================================================================================================
  #
  #-----------------------------------------------------------------------------------------------------------
  @$lex = ->
    pipeline = []
    pipeline.push @$prepare()
    pipeline.push @$group_chrs_by_ucc()
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

FM = {}
f.apply FM.LEXER = {}


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
    # [ 'y = x ** 2 for x in [ 1, 2, 3, ]','']
    # [ '12ab','']
    # [ '123abc$%\n2\n3\n456 xyz\n\n','']
    # [ '1\n#','']
    # [ '2\r#','']
    # [ '3\r\n#','']
    # [ '4\n\r#','']
    # [ '5\u2028#','']
    # [ '6\u2029#','']
    # [ 'u-cjk-xb/22f33 𢼳 ⿰匡夊','']
    [ 'a&#x21;z','']
    # [ 'a&#x21;bc&#x22;de','']
    # [ 'u-cjk-xb/22f33 &#x22f33; ⿰匡夊','']
    ]
  thin_out  = ( list ) -> ( x for x in list when x isnt '' )
  join      = ( list ) -> list.join '_'
  self = this
  step ( resume ) ->
    for [ probe, matcher, ] in probes_and_matchers
      urge rpr probe
      lines = yield FM.LEXER.lex probe, resume
      for line in lines
        whisper JSON.stringify line
        warn line.position, rpr line.image
        for chunk in line.chunks
          help '  ' + JSON.stringify chunk
      # result  = join thin_out probe.split splitter
      # debug thin_out probe.split splitter
      # whisper rpr result
      # whisper rpr matcher
      # T.ok result is matcher
    T.end()
    return null
  #.........................................................................................................
  return null




