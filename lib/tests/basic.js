// Generated by CoffeeScript 2.0.0-alpha1
(function() {
  'use strict';
  var $, $async, CND, FLOWMATIC, HELPERS, PS, TAP, badge, debug, echo, help, info, rpr, step, urge, warn, whisper;

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'FLOWMATIC/TESTS/BASIC';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  TAP = require('tap');

  FLOWMATIC = require('../..');

  PS = require('pipestreams');

  $ = PS.$, $async = PS.$async;

  step = require('coffeenode-suspend').step;


  /* TAINT refactor HELPERS */

  HELPERS = {};

  HELPERS.transpile_text_to_protocol = function(text, protocol_transform, handler) {
    var pipeline, Ø;
    pipeline = [];
    Ø = (x) => {
      return pipeline.push(x);
    };
    Ø(PS.new_text_source(text));
    Ø(FLOWMATIC.LEXER.$lex());
    Ø(FLOWMATIC.ARABIKA.$transpile());
    Ø(protocol_transform);
    Ø((() => {
      var Z;
      Z = [];
      return $('null', function(collection, send) {
        if (collection != null) {
          send(Z = collection);
        } else {
          handler(null, Z);
        }
        return null;
      });
    })());
    Ø(PS.$drain());
    PS.pull(...pipeline);
    return null;
  };

  HELPERS.transpile_A = function(text, handler) {
    return step(function*(resume) {
      var protocol, recorder;
      recorder = FLOWMATIC.PROTOCOL.$cs_tokens_as_protocol_A();
      protocol = (yield HELPERS.transpile_text_to_protocol(text, recorder, resume));
      return handler(null, protocol);
    });
  };

  HELPERS.transpile_B = function(text, handler) {
    return step(function*(resume) {
      var protocol, recorder;
      recorder = FLOWMATIC.PROTOCOL.$cs_tokens_as_protocol_B();
      protocol = (yield HELPERS.transpile_text_to_protocol(text, recorder, resume));
      return handler(null, protocol);
    });
  };

  TAP.test("indentation (1)", function(T) {
    step(function*(resume) {
      var matcher, probe, protocol;
      urge('"indentation (1)", ( T ) ->');
      probe = "a\n  b\n    c\n  d";
      matcher = "(identifier|'a')\n> (identifier|'b')\n> (identifier|'c') <\n(identifier|'d') <";
      protocol = (yield HELPERS.transpile_B(probe, resume));
      if (typeof error !== "undefined" && error !== null) {
        throw error;
      }
      help('\n' + probe);
      debug('\n' + protocol);
      T.ok(CND.equals(protocol, matcher));
      return T.end();
    });
    return null;
  });

  TAP.test("indentation (2)", function(T) {
    step(function*(resume) {
      var matcher, probe, protocol;
      urge('"indentation (2)", ( T ) ->');
      probe = "a\n    b\n      c\n  d";
      matcher = "(identifier|'a')\n> > (identifier|'b')\n> (identifier|'c') < <\n(identifier|'d') <";
      protocol = (yield HELPERS.transpile_B(probe, resume));
      if (typeof error !== "undefined" && error !== null) {
        throw error;
      }
      help('\n' + probe);
      debug('\n' + protocol);
      T.ok(CND.equals(protocol, matcher));
      return T.end();
    });
    return null;
  });

  TAP.test("assorted", function(T) {
    step(function*(resume) {
      var i, len, matcher, probe, probes_and_matchers, protocol, ref;
      probes_and_matchers = [["f foo-bar", "(identifier|'f') (lws|' ') (identifier|'foo-bar')"], ["a-b\n\n  a - b", "(identifier|'a-b')\n> (identifier|'a') (lws|' ') (identifier|'-') (lws|' ') (identifier|'b') <"], ["one + two ** three + f -> 42", "(identifier|'one') (lws|' ') (operator|'+') (lws|' ') (identifier|'two') (lws|' ') (operator|'**') (lws|' ') (identifier|'three') (lws|' ') (operator|'+') (lws|' ') (identifier|'f') (lws|' ') (function|'->') (lws|' ') (number|'42')"], ["d = ~isa: :foo", "(identifier|'d') (lws|' ') (operator|'=') (lws|' ') (key|'~isa') (colon|':') (lws|' ') (keystring|'\\'foo\\'')"]];
      for (i = 0, len = probes_and_matchers.length; i < len; i++) {
        ref = probes_and_matchers[i], probe = ref[0], matcher = ref[1];
        protocol = (yield HELPERS.transpile_B(probe, resume));
        debug(JSON.stringify([probe, protocol]));
        T.ok(CND.equals(protocol, matcher));
      }
      return T.end();
    });
    return null;
  });

  TAP.test("assorted 2", function(T) {
    step(function*(resume) {
      var i, len, matcher, probe, probes_and_matchers, protocol, ref;
      probes_and_matchers = [["d := expression | '(' + expression + ')'", ''], ["f'foo'", ''], ["y{* x *}z", ''], ["with read-file 'x.txt' as file then f file", '']];
      for (i = 0, len = probes_and_matchers.length; i < len; i++) {
        ref = probes_and_matchers[i], probe = ref[0], matcher = ref[1];
        protocol = (yield HELPERS.transpile_B(probe, resume));
        urge(probe);
        help(protocol);
      }
      return T.end();
    });
    return null;
  });

  TAP.test("strings etc.", function(T) {
    step(function*(resume) {
      var i, len, matcher, probe, probes_and_matchers, protocol, ref;
      probes_and_matchers = [["'123'", ''], ["'''123'''", ''], ['"123"', ''], ['"""123"""', ''], ['`123`', ''], ['```123```', ''], ["'x'", ''], ["'''x'''", ''], ['"x"', ''], ['"""x"""', ''], ['`x`', ''], ['```x```', ''], ["'x y z'", ''], ["'''x y z'''", ''], ['"x y z"', ''], ['"""x y z"""', ''], ['`x y z`', ''], ['```x y z```', '']];
      for (i = 0, len = probes_and_matchers.length; i < len; i++) {
        ref = probes_and_matchers[i], probe = ref[0], matcher = ref[1];
        protocol = (yield HELPERS.transpile_B(probe, resume));
        urge(probe);
        help(protocol);
      }
      return T.end();
    });
    return null;
  });

  TAP.test("brackets etc.", function(T) {
    step(function*(resume) {
      var i, len, matcher, probe, probes_and_matchers, protocol, ref;
      probes_and_matchers = [['for x in [ 9 12', ''], ['a [ b', ''], ['a ] b', ''], ['a ( b', ''], ['a ) b', ''], ['a { b', ''], ['a } b', '']];
      for (i = 0, len = probes_and_matchers.length; i < len; i++) {
        ref = probes_and_matchers[i], probe = ref[0], matcher = ref[1];
        protocol = (yield HELPERS.transpile_B(probe, resume));
        urge(probe);
        help(protocol);
      }
      return T.end();
    });
    return null;
  });

  TAP.test("special strings", function(T) {
    step(function*(resume) {
      var i, len, matcher, probe, probes_and_matchers, protocol, ref;
      probes_and_matchers = [['f"x"', ''], ['u-cjk/4e0b\t下 ⿱一卜', ''], ['u-cjk/4e0c\t丌 ⿱一&jzr#xe110;', ''], ['u-cjk/4e0d\t不 ⿸丆卜', ''], ['u-cjk-xb/27fb5\t𧾵 ⿺走矍', '']];
      for (i = 0, len = probes_and_matchers.length; i < len; i++) {
        ref = probes_and_matchers[i], probe = ref[0], matcher = ref[1];
        protocol = (yield HELPERS.transpile_B(probe, resume));
        urge(probe);
        help(protocol);
      }
      return T.end();
    });
    return null;

    /*
    FLOWMATIC.transpile """
      aaa ** bbb
      is-first = yes
      type-of-x = CND/type-of x
      a = d/x/g
      d = ~isa: :foo
      e = 1_000_000
       * s{ :d, :j, }
      f = ->
        foo
        bar
      """
     */
  });

}).call(this);

//# sourceMappingURL=basic.js.map