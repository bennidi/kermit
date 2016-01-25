{PassThrough, Transform, Writable} = require 'stream'
fs = require 'fs-extra'
_ = require 'lodash'
{obj} = require './tools.coffee'
dateFormat = require 'dateformat'

# Aggregates log message and additional (meta-)data. Constructed whenever
# the log() method of {LogHub} is called with more than just the message.
# @private
class LogEntry

  constructor: (@msg, @data) ->
    @tags = @data?.tags
    delete @data.tags

# Format log messages
# @abstract
class Formatter

  #@abstract
  fromString: (lvl, msg) ->

  #@abstract
  fromEntry: (lvl, entry) ->

class DefaultFormatter extends Formatter

  extractTags = (tags) ->
    if _.isEmpty tags then "" else " [#{tags}]"

  fromString : (lvl, msg) ->
    time = dateFormat new Date(), "d/mm HH:MM:ss.l"
    entry = "[#{time}] #{lvl.toUpperCase()} - #{msg}\n"

  fromEntry : (lvl, entry) ->
    tags = extractTags entry.tags
    data = if _.isEmpty entry.data then "" else "(#{obj.print entry.data, 3})"
    time = dateFormat new Date(), "d/mm HH:MM:ss.l"
    entry = "[#{time}] #{lvl.toUpperCase()}#{tags} - #{entry.msg} #{data}\n"

class LogFormats

  @llog : () -> new DefaultFormatter

class LogAppender

  constructor: (params) ->
    @sink = params?.sink

  # @private
  # @abstract
  initialize: () ->

class FileAppender extends LogAppender

  constructor: (params) -> super sink : fs.createWriteStream(params.filename, flags : 'a')

class ConsoleAppender extends LogAppender

  constructor: () -> super sink : process.stdout

class LogFormatHandler extends Transform

  constructor : (@formatter, @level) ->
    super objectMode : true
    @setMaxListeners 100

  _transform: (chunk, enc, next) ->
    msg = switch
      when chunk.constructor is String then @formatter.fromString @level, chunk
      when chunk instanceof Buffer then @formatter.fromString @level, chunk.toString()
      when chunk instanceof LogEntry then @formatter.fromEntry @level, chunk
      else "Unexpected type of log message #{chunk}"
    @push msg
    next()

class Appenders

  instance = null

  @get: () ->
    instance ?= new Appenders

  # @private
  constructor: (@registry = {}) ->
    @register 'console', ConsoleAppender
    @register 'file', FileAppender

  register : (alias, factory) ->
    @registry[alias] = factory

  create : (def) ->
    new @registry[def.type] def

class LogHub

  @defaultOpts : () ->
    appenders : Appenders.get()
    destinations : [
      {
        appender:
          type : 'console'
        levels: ['info', 'warn', 'error', 'debug']
      },
      {
        appender:
          type : 'file'
          filename : '/tmp/all.log'
        levels: ['info', 'warn', 'error', 'debug']
      }
    ]
    levels : ['info', 'warn', 'error', 'debug']

  constructor : (opts = {}) ->
    @opts = _.merge {}, LogHub.defaultOpts(), opts, (a,b) -> if _.isArray a then b
    @initialize()

  #@private
  initialize: () ->
    fs.mkdirsSync @opts.basedir if @opts.basedir
    @dispatcher = {}
    for level in @opts.levels
      connector = new PassThrough(objectMode : true)
      connector.setMaxListeners(100) # what number here?
      @dispatcher[level] = connector
    @addDestination destination for destination in @opts.destinations

  addDestination: (destination) ->
    appender = switch
      when destination.appender.type.constructor is String then @opts.appenders.create destination.appender
      when destination.appender.type instanceof Function then new destination.appender.type destination.appender
      else throw new Error "Unknown specification of appender type: #{destination.appender.type}"
    for level in destination.levels
      if not @dispatcher[level] then throw new Error "Log level #{level} not defined"
      formatter = destination.formatter or LogFormats.llog()
      @dispatcher[level]
        .pipe new LogFormatHandler formatter, level
        .pipe appender.sink

  log : (lvl, msg, data) ->
    if data
      @dispatcher[lvl]?.push new LogEntry msg, data
    else
      @dispatcher[lvl]?.push msg

  logger: () -> new Logger @opts.levels, @

# Wrapper around {LogHub} that provides a method for each available log level
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