
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

thin_out  = ( list ) -> ( x for x in list when x isnt '' )
shorten   = ( text ) -> if text.length < 2 then text else text[ 1 ... text.length - 1 ]
chrrpr    = ( text ) -> if ( /^\s+$/.test text ) then ( CND.reverse shorten rpr text ) else text
flag      = yes
toggle    = -> flag = not flag
get_color = ( c1, c2 ) -> ( x ) -> if toggle() then c1 x else c2 x
color     = get_color steel, orange
rainbow   = ( list ) -> ( ( color chrrpr x ) for x in list ).join ''
join      = ( list ) -> list.join '_'



###
coffee> ( 'ab++c23\nd"xyzd\t++dy'.split /([0-9]+|[a-w]+|[-+]+|\s+|["])/ ).join '_'
'_ab__++__c__23__\n__d__"__a_xyz_d__\t__++__d_y'
'_ab__++__c__23__\n__d__"_xyz_d__\t__++__d_y'
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
    ]
  splitter  = Xregex """([0-9]+|[a-w]+|[-+]+|\s+|["])"""
  thin_out  = ( list ) -> ( x for x in list when x isnt '' )
  join      = ( list ) -> list.join '_'
  for [ probe, matcher, ] in probes_and_matchers
    urge rpr probe
    result = join thin_out probe.split splitter
    debug thin_out probe.split splitter
    whisper rpr result
    whisper rpr matcher
    T.ok result is matcher
  T.end()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "Unicode categories (1)", ( T ) ->
  debug '-----------------------------------------------'
  debug "Unicode categories (1)"
  debug '-----------------------------------------------'
  splitter            = Xregex """(?A)(\\pL+|\\s+|["])"""
  probes_and_matchers = [
    [ 'helo world',   'ab_++_c_23_\n_d_"_a_xyz_d_\t_++_d_y', ]
    [ 'lee7speak',   'ab_++_c_23_\n_d_"_a_xyz_d_\t_++_d_y', ]
    [ 'ab++c23\n\n\nd"axyzd\t++dy',   'ab_++_c_23_\n_d_"_a_xyz_d_\t_++_d_y', ]
    [ 'ab++c23\nd"xyzd\t++dy',  'ab_++_c_23_\n_d_"_xyz_d_\t_++_d_y', ]
    ]
  for [ probe, matcher, ] in probes_and_matchers
    urge CND.white shorten rpr probe
    tokens = thin_out probe.split splitter
    result = join tokens
    # debug thin_out probe.split splitter
    help rainbow tokens
    # whisper rpr matcher
    # T.ok result is matcher
  T.end()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "Unicode categories (2)", ( T ) ->
  debug '-----------------------------------------------'
  debug "Unicode categories (2)"
  debug '-----------------------------------------------'
  splitter  = []
  x         = []
  splitter.push '(?A)'
  splitter.push '('
  for { name, alias, } in categories
    x.push "\\p#{name}+"
  splitter.push x.join '|'
  splitter.push ')'
  splitter            = Xregex splitter.join ''
  probes_and_matchers = [
    [ 'helo world',   'ab_++_c_23_\n_d_"_a_xyz_d_\t_++_d_y', ]
    [ 'lee7speak',   'ab_++_c_23_\n_d_"_a_xyz_d_\t_++_d_y', ]
    [ 'ab++c23\n\n\nd"axyzd\t++dy',   'ab_++_c_23_\n_d_"_a_xyz_d_\t_++_d_y', ]
    [ 'ab++c23\nd"xyzd\t++dy',  'ab_++_c_23_\n_d_"_xyz_d_\t_++_d_y', ]
    ]
  for [ probe, matcher, ] in probes_and_matchers
    urge CND.white shorten rpr probe
    tokens = thin_out probe.split splitter
    result = join tokens
    # debug thin_out probe.split splitter
    help rainbow tokens
    # whisper rpr matcher
    # T.ok result is matcher
  T.end()
  #.........................................................................................................
  return null












