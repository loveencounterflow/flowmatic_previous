
( require 'tap' ).test "skip", ( T ) -> T.end()

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
