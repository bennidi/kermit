{PassThrough, Transform, Writable} = require 'stream'
fs = require 'fs-extra'
_ = require 'lodash'

class LogFormats

  extractTags = (data) ->
    tags = if data?.tags then " [#{data.tags}]" else ""
    delete data?.tags
    tags

  @llog : (newline = true) ->
      (lvl, msg, data) ->
        tags = extractTags data
        data = if _.isEmpty data then "" else "(#{JSON.stringify data})"
        entry = "[#{new Date().toISOString()}] #{lvl.toUpperCase()}#{tags} - #{msg} #{data}"
        if newline then entry + "\n" else entry



class LogEntry
  emptyArray = []

  constructor: (@lvl, @msg, @data) ->

  tags: () ->
    @data?.tags or emptyArray

class LogAppender

  constructor: (@sink, @formatter = LogFormats.default) ->

  # @private
  # @abstract
  initialize: () ->

class FileAppender extends LogAppender

  constructor: (@filename, @formatter = LogFormats.llog()) ->
    #super new FileLogStream @filename, @formatter
    super null, @formatter

  initialize : () ->
    @sink = fs.createWriteStream(@filename, flags : 'a')

class ConsoleLogStream extends Writable

  _write: (chunk, enc, next) ->
    console.log chunk.toString()
    next()

class ConsoleAppender extends LogAppender

  constructor: (@formatter = LogFormats.llog false) ->
    super new ConsoleLogStream, @formatter

class LogFormatter extends Transform

  constructor : (@formatter = format, @level) ->
    super objectMode : true

  _transform: (chunk, enc, next) ->
    msg = switch
      when chunk.constructor is String then @formatter @level, chunk
      when chunk instanceof Buffer then @formatter @level, chunk.toString()
      when chunk instanceof LogEntry then @formatter @level, chunk.msg, chunk.data
      else "Unexpected type of log message #{chunk}"
    @push msg
    next()


class LogHub

  @defaultOpts : () ->
    basedir : "/tmp/loghub"
    destinations : [
      {
        appender: new ConsoleAppender
        levels: ['info', 'warn', 'error', 'debug']
      }
    ]
    levels : ['info', 'warn', 'error', 'debug']

  constructor : (opts = {}) ->
    @opts = _.merge {}, LogHub.defaultOpts(), opts, (a,b) -> if _.isArray a then b
    @_initialize()

  _initialize: () ->
    fs.mkdirsSync "#{@opts.basedir}/logs"
    @dispatcher = {}
    for level in @opts.levels
      connector = new PassThrough(objectMode : true)
      connector.setMaxListeners(100) # what number here?
      @dispatcher[level] = connector
    @addDestination destination for destination in @opts.destinations

  addDestination: (destination) ->
    destination.appender.initialize()
    for level in destination.levels
      if not @dispatcher[level] then throw new Error "Log level #{level} not defined"
      formatter = destination.appender.formatter or LogFormats.llog()
      @dispatcher[level]
        .pipe new LogFormatter formatter, level
        .pipe destination.appender.sink

  log : (lvl, msg, data) ->
    if data
      @dispatcher[lvl]?.push new LogEntry lvl, msg, data
    else
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