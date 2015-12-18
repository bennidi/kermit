{PassThrough, Transform, Writable} = require 'stream'
merge = require 'merge'
fs = require 'fs-extra'

class LogFormats

  @default : (lvl, msg, data) ->
    "#{lvl} - #{data?.tags?} - #{msg}\n"

class LogAppender

  constructor: (@sink, @formatter = LogFormats.default) ->

class FileLogStream extends Writable

  constructor: (@filename)-> super

  _write: (chunk, enc, next) ->
    fs.appendFileSync @filename, chunk
    next()

class FileAppender extends LogAppender

  constructor: (@filename, @formatter = LogFormats.default) ->
    #super new FileLogStream @filename, @formatter
    super fs.createWriteStream(@filename, flags : 'a'), @formatter

class ConsoleLogStream extends Writable

  _write: (chunk, enc, next) ->
    console.log chunk.toString()
    next()

class ConsoleAppender extends LogAppender

  constructor: (@formatter = LogFormats.default) -> super new ConsoleLogStream, @formatter

class LogFormatter extends Transform

  constructor : (@formatter = format, @level) ->
    super objectMode : true

  _transform: (chunk, enc, next) ->
    msg = switch
      when chunk.constructor is String then @formatter @level, chunk
      when chunk instanceof Buffer then @formatter @level, chunk.toString()
      when chunk instanceof Object then @formatter @level, chunk.msg, chunk
      else "Unexpected type of log message #{chunk}"
    @push msg
    next()


class LogHub

  @defaultOpts : () ->
    destinations : [
      {
        appender: new LogAppender new ConsoleLogStream
        levels: ['info', 'warn', 'error', 'debug']
      }
    ]
    levels : ['info', 'warn', 'error', 'debug']

  constructor : (opts = {}) ->
    @opts = merge.recursive LogHub.defaultOpts(), opts
    @_initialize()
    @addDestination destination for destination in @opts.destinations

  _initialize: () ->
    @dispatcher = {}
    for level in @opts.levels
      connector = new PassThrough(objectMode : true)
      connector.setMaxListeners(100) # what number here?
      @dispatcher[level] = connector

  addDestination: (destination) ->
    for level in destination.levels
      if not @dispatcher[level] then throw new Error "Log level #{level} not defined"
      formatter = destination.appender.formatter or LogFormats.default
      @dispatcher[level]
        .pipe new LogFormatter formatter, level
        .pipe destination.appender.sink

  log : (lvl, msg, data) ->
    if data
      data.msg = msg
      msg = data
    @dispatcher[lvl]?.push msg

  logger: () -> new Logger @opts.levels, @

class Logger

  logHandler = (lvl, hub) -> (msg, data) -> hub.log lvl, msg, data

  constructor: (levels = [], @hub) ->
    for level in levels
      @[level] = logHandler level, @hub


module.exports = {
  LogHub
  LogAppender
  FileAppender
  ConsoleAppender
}