// Generated by CoffeeScript 1.6.3
(function() {
  var MONA, TEXT, TRM, TYPES, alert, badge, cell, csv, debug, echo, eol, help, info, line, log, parenthesized, parse, parseCSV, quotedCell, quotedChar, rpr, warn, whisper;

  TYPES = require('coffeenode-types');

  TEXT = require('coffeenode-text');

  TRM = require('coffeenode-trm');

  rpr = TRM.rpr.bind(TRM);

  badge = 'XLTX';

  log = TRM.get_logger('plain', badge);

  info = TRM.get_logger('info', badge);

  whisper = TRM.get_logger('whisper', badge);

  alert = TRM.get_logger('alert', badge);

  debug = TRM.get_logger('debug', badge);

  warn = TRM.get_logger('warn', badge);

  help = TRM.get_logger('help', badge);

  echo = TRM.echo.bind(TRM);

  /* TAINT why can't we `require` without route???*/


  /* https://github.com/sykopomp/mona*/


  MONA = require('../node_modules/mona-parser');

  csv = function() {
    return MONA.splitEnd(line(), eol());
  };

  line = function() {
    return MONA.split(cell(), MONA.string(','));
  };

  cell = function() {
    return MONA.or(quotedCell(), MONA.text(MONA.noneOf(',\n\r')));
  };

  quotedCell = function() {
    return MONA.between(MONA.string('"'), MONA.string('"'), MONA.text(quotedChar()));
  };

  quotedChar = function() {
    return MONA.or(MONA.noneOf('"'), MONA.and(MONA.string('""'), MONA.value('"')));
  };

  eol = function() {
    var str;
    str = MONA.string;
    return MONA.or(str('\n\r'), str('\r\n'), str('\n'), str('\r'), "end of line");
  };

  parseCSV = function(source) {
    return parse(csv(), source);
  };

  parse = function(parser, source, options) {
    var column_nr, error, file, line_nr, name, position, _ref;
    try {
      return MONA.parse(parser, source, options);
    } catch (_error) {
      error = _error;
      position = error['position'];
      name = position != null ? position['name'] : void 0;
      line_nr = position != null ? position['line'] : void 0;
      column_nr = position != null ? position['column'] : void 0;
      if ((line_nr != null) && (column_nr != null)) {
        line = (TEXT.lines_of(source))[line_nr - 1];
        file = (_ref = "in " + name + " ") != null ? _ref : '';
        warn("Error " + file + "on line #" + line_nr + ", column " + column_nr + ":");
        warn(line);
        warn(((new Array(column_nr)).join(' ')).concat('^'));
      }
      throw error;
    }
  };

  parenthesized = function(parser) {
    return MONA.sequence(function(s) {
      var close, data, open;
      open = s(MONA.string('('));
      data = s(parser);
      close = s(MONA.string(')'));
      return MONA.value(data);
    });
  };

  info(parseCSV("foo,\"bar\"\nbaz,quux\n"));

  info(parse(MONA.value("just a value"), ''));

  info(parse(parenthesized(MONA.string("foo!")), "(foo!)"));

  info(parse(MONA.float(), "34.556"));

  info(parse(MONA.float(), "34.556e10"));

}).call(this);