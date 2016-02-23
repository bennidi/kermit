{Extension} = require '../Extension'
{Phase} = require '../RequestItem'
{QueueSystem} = require '../QueueManager'
through = require 'through2'
stream = require 'stream'
{ContentType} = require '../Pipeline'
{LogStream} = require './tools.streams'

# Record phase transitions of all items and assert the a specified series of
# transitions has been made
class TransitionRecorder extends Extension

  # @nodoc
  constructor: (@done)->
    super
      INITIAL: (item) -> @apply item, 'INITIAL'
      SPOOLED: (item) -> @apply item, 'SPOOLED'
      READY: (item) -> @apply item, 'READY'
      FETCHING: (item) -> @apply item, 'FETCHING'
      FETCHED: (item) -> @apply item, 'FETCHED'
      COMPLETE: (item) -> @apply item, 'COMPLETE'
      ERROR: (item) -> @apply item, 'ERROR'
      CANCELED : (item) -> @apply item, 'CANCELED'
    @expected = {}
    @items = 0

  # @nodoc
  apply: (item, phase) ->
    @expected[item.url()] = @expected[item.url()].filter (expected) -> expected isnt phase
    @log.info? "Expected for #{item.url()}: #{@expected[item.url()]}"
    expect(@expected[item.url()]).not.contain(phase)
    @items-- if @expected[item.url()].length is 0
    if @items is 0
      @done()

  validate: (url, expected) ->
    @items++
    @expected[url] = expected

class RejectingExtension extends Extension

  constructor: ->
    super INITIAL: @apply
    @invocations = 0

  apply: (item) ->
    @log.info? "Rejecting " + item.url()
    item.cancel("Rejected by RejectingExtension")

class MockContext
  execute: (item) -> item
  schedule: (item, url) -> item.subitem url
  config:
    basePath : -> "somepath"
  queue: new QueueSystem
  share: (property, value ) =>
    @[property] = value
  crawler :
    enqueue: (item) -> item
  log :
    info : (msg) -> console.log msg
    debug : (msg) -> console.log msg
    error : (msg) -> console.log msg
    trace : (msg) -> console.log msg
    log : (level, msg) -> console.log msg

class ResponseStreamLogger extends Extension

  constructor: (shouldLog = false) ->
    super INITIAL: (item) ->
      item.pipeline().stream ContentType([/.*/]), new LogStream shouldLog

class CountingStream extends stream.Transform

  constructor: (@cnt = 0) -> super

  _transform: (chunk, enc, next) ->
    @cnt++
    @push chunk
    next()

class LogStream extends stream.Writable

  constructor: (@shouldLog = true) -> super

  _write: (chunk, enc, next) ->
    console.log chunk.toString() if @shouldLog
    next()

module.exports = {
  RejectingExtension
  TransitionRecorder
  MockContext
  ResponseStreamLogger
  CountingStream
  LogStream
}