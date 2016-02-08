{LogHub, LogAppender} = require './Logging'
{CountingStream, LogStream} = require './util/tools.streams'
through = require 'through2'

describe  'LogHub',  ->
  describe 'can be used to log messages.', ->

    it '# handles different log levels independently', () ->
      info = new CountingStream
      error = new CountingStream
      warn = new CountingStream
      debug = new CountingStream
      hub = new LogHub destinations : [
        {appender:
          type : LogAppender
          sink : info
        levels : ['info']}
        {appender:
          type : LogAppender
          sink : error
        levels : ['error']}
        {appender:
          type : LogAppender
          sink : warn
        levels : ['warn']}
        {appender:
          type : LogAppender
          sink : debug
        levels : ['debug']}

      ]
      hub.log "info", "Some message"
      hub.log "warn", "Some message"
      hub.log "debug", "Some message"
      hub.log "error", "Some message"
      expect(info.cnt).to.equal(1)
      expect(error.cnt).to.equal(1)
      expect(debug.cnt).to.equal(1)
      expect(warn.cnt).to.equal(1)

    it '# different log levels can be aggregated', () ->
      all = new CountingStream
      hub = new LogHub destinations : [
        {appender:
          type : LogAppender
          sink : all
        levels : ['info', 'warn', 'debug', 'error']}
      ]
      hub.log "info", "Some message"
      hub.log "warn", "Some message"
      hub.log "debug", "Some message"
      hub.log "error", "Some message"
      expect(all.cnt).to.equal(4)


    it '# exposes a logger with methods for each defined log level', () ->
      all = new CountingStream
      hub = new LogHub destinations : [
        {
          appender:
            type : LogAppender
            sink: all
          levels : ['info', 'warn', 'debug', 'error']
        }
      ]
      log = hub.logger()
      log.info "Some message"
      log.warn "Some message"
      log.debug "Some message"
      log.error "Some message"
      log.trace? "This log level does not exists"
      expect(all.cnt).to.equal(4)

    it '# supports logging of additional data', () ->
      hub = new LogHub
      hub.logger().info 'My message', tags : ['Streaming','AnotherTag'] for i in [1..10]