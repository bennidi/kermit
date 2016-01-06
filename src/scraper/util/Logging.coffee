{PassThrough, Transform, Writable} = require 'stream'
fs = require 'fs-extra'
_ = require 'lodash'

class LogEntry

  constructor: (@lvl, @msg, @data) ->
    @tags = @data?.tags
    delete @data.tags

# @abstract
class Formatter

  constructor : (@newline = true) ->

  #@abstract
  fromString: (lvl, msg) ->

  #@abstract
  fromEntry: (lvl, entry) ->

class DefaultFormatter extends Formatter

  constructor : (@newline = true) -> super @newline

  extractTags = (tags) ->
    if _.isEmpty tags then "" else " [#{tags}]"

  fromString : (lvl, msg) ->
    entry = "[#{new Date().toISOString()}] #{lvl.toUpperCase()} - #{msg}"
    if @newline then entry + "\n" else entry

  fromEntry : (lvl, entry) ->
    tags = extractTags entry.tags
    data = if _.isEmpty entry.data then "" else "(#{JSON.stringify entry.data})"
    entry = "[#{new Date().toISOString()}] #{lvl.toUpperCase()}#{tags} - #{entry.msg} #{data}"
    if @newline then entry + "\n" else entry

class LogFormats

  @llog : (newline = true) -> new DefaultFormatter newline

class LogAppender

  constructor: (@sink, @formatter = LogFormats.llog()) ->

  # @private
  # @abstract
  initialize: () ->

class FileAppender extends LogAppender

  constructor: (@filename, @formatter = LogFormats.llog()) ->
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

  constructor : (@formatter, @level) ->
    super objectMode : true

  _transform: (chunk, enc, next) ->
    msg = switch
      when chunk.constructor is String then @formatter.fromString @level, chunk
      when chunk instanceof Buffer then @formatter.fromString @level, chunk.toString()
      when chunk instanceof LogEntry then @formatter.fromEntry @level, chunk
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