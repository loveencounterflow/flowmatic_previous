// Generated by CoffeeScript 2.0.0-beta2
(function() {
  var $, CND, CS, FLOWMATIC, PS, SourceType, alert, badge, debug, echo, help, info, lex, log, map, rpr, urge, warn, whisper,
    splice = [].splice,
    indexOf = [].indexOf;

  CND = require('cnd');

  rpr = CND.rpr.bind(CND);

  badge = 'DEMO-COFFEE-LEX';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  PS = require('pipestreams');

  ({$, map} = PS);

  CS = require('coffeescript');

  FLOWMATIC = require('..');

  ({
    default: lex,
    SourceType
  } = require('stupid-coffee-lexer'));

  this._image_from_section = function(section) {
    var token;
    return ((function() {
      var i, len, results;
      results = [];
      for (i = 0, len = section.length; i < len; i++) {
        token = section[i];
        results.push(token.image);
      }
      return results;
    })()).join('');
  };

  this._typeimage_from_section = function(section) {
    var token;
    return ((function() {
      var i, len, results;
      results = [];
      for (i = 0, len = section.length; i < len; i++) {
        token = section[i];
        results.push(token.type);
      }
      return results;
    })()).join(',');
  };

  this.$exponentiation = function() {
    return PS.$gliding_window(4, (section) => {
      var image, ref;
      image = this._image_from_section(section);
      if (image === ' ** ') {

        /* TAINT use proper method */
        splice.apply(section, [1, 2].concat(ref = {
          type: 'operator',
          start: 0,
          stop: 0,
          image: '**',
          specifier: 'operator/**'
        })), ref;
      }
      return null;
    });
  };

  this.$xidentifiers = function() {
    var flush, id_collector, id_start, send;
    send = null;
    id_collector = [];
    id_start = null;
    flush = function() {
      var id_count, image, stop;
      if ((id_count = id_collector.length) > 0) {
        image = id_collector.join('');
        stop = id_start + id_count;
        send({
          start: id_start,
          stop,
          type: 'identifier',
          image,
          isxid: true,
          count: id_count
        });
        id_collector.length = 0;
        id_start = null;
      }
      return null;
    };
    return $('null', (token, send_) => {
      var image, isxid, start;
      send = send_;
      if (token != null) {
        ({image, start, isxid} = token);
        if (isxid) {
          if (id_start == null) {
            id_start = start;
          }
          id_collector.push(image);
        } else {
          flush();
          send(token);
        }
      } else {
        flush();
      }
      return null;
    });
  };

  this.$relabel_slash = function() {
    return map((token) => {
      if (token.image === '/') {
        token.type = 'slash';
      }
      return token;
    });
  };

  this.$slash_as_dot = function() {
    return PS.$gliding_window(3, (section) => {
      var typeimage;
      typeimage = this._typeimage_from_section(section);
      if (typeimage === 'identifier,slash,identifier') {
        section[1].type = 'slashdot';
      }
      return null;
    });
  };

  this.$number_with_underscores = function() {

    /* acc. to http://www.regular-expressions.info/floatingpoint.html */
    var pattern;
    pattern = /^_[_0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?$/;
    return PS.$gliding_window(2, (section) => {
      var blank, cs, image, isxid, new_token, start, stop, t0, t1, type, typeimage;
      typeimage = this._typeimage_from_section(section);
      if (typeimage === 'number,identifier') {
        [t0, t1] = section;
        if (pattern.test(t1.image)) {
          start = t0.start;
          stop = t1.stop;
          image = t0.image + t1.image;
          cs = image.replace(/_/g, '');
          blank = false;
          isxid = false;
          type = 'number';
          new_token = {start, stop, type, image, cs, blank, isxid};
          splice.apply(section, [0, 2].concat(new_token)), new_token;
        }
      }
      return null;
    });
  };

  this.$key_with_sigil = function() {
    var sigils;
    sigils = ['~', '%'];
    return PS.$gliding_window(4, (section) => {
      var blank, cs, image, isxid, new_token, ref, start, stop, t0, t1, t2, t3, type;
      [t0, t1, t2, t3] = section;
      if ((ref = t0.image, indexOf.call(sigils, ref) >= 0) && t1.type === 'identifier' && t2.image === ':' && t3.blank) {
        start = t0.start;
        stop = t1.stop;
        image = t0.image + t1.image;
        cs = rpr(image);
        blank = false;
        isxid = false;
        type = 'key';
        new_token = {start, stop, type, image, cs, blank, isxid};
        splice.apply(section, [0, 2].concat(new_token)), new_token;
      }
      return null;
    });
  };

  this.$keystring = function() {
    var prv_blank;
    prv_blank = true;
    return PS.$gliding_window(3, (section) => {
      var blank, image, isxid, new_token, start, stop, t0, t1, t2, type;
      [t0, t1, t2] = section;
      if (t0.blank && (t1.image === ':') && (t2.type === 'identifier')) {
        start = t1.start;
        stop = t2.stop;
        image = rpr(t2.image);
        blank = false;
        isxid = false;
        type = 'keystring';
        new_token = {start, stop, type, image, blank, isxid};
        splice.apply(section, [1, 2].concat(new_token)), new_token;
      }
      return null;
    });
  };

  this._$translate_slashdot = function() {
    return PS.$gliding_window(3, (section) => {
      var typeimage;
      typeimage = this._typeimage_from_section(section);
      if (typeimage === 'identifier,slashdot,identifier') {
        section[1].type = 'dot';
        section[1].cs = '.';
      }
      return null;
    });
  };

  this._$translate_dashed_identifier = function() {
    return map(function(token) {
      var cs_image, image, type;
      ({type, image} = token);
      if (type === 'identifier') {
        cs_image = image.replace(/-/g, '_');
        if (cs_image !== image) {
          token.cs = cs_image;
        }
      }
      return token;
    });
  };

  this.$transpile = function() {
    var pipeline, Ø;
    pipeline = [];
    Ø = (x) => {
      return pipeline.push(x);
    };
    Ø(this.$exponentiation());
    Ø(this.$xidentifiers());
    Ø(this.$key_with_sigil());
    Ø(this.$keystring());
    Ø(this.$relabel_slash());
    Ø(this.$slash_as_dot());
    Ø(this.$number_with_underscores());
    return PS.pull(...pipeline);
  };

}).call(this);

//# sourceMappingURL=basic-arabika.js.map
