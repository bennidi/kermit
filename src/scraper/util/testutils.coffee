{Extension, ExtensionDescriptor} = require '../Extension.coffee'
{Status} = require '../CrawlRequest.coffee'
{QueueManager} = require '../QueueManager.coffee'
through = require 'through2'
stream = require 'stream'

class TransitionRecorder extends Extension

  # @nodoc
  constructor: (@done)->
    super
      INITIAL: @apply
      SPOOLED: @apply
      READY: @apply
      FETCHING: @apply
      FETCHED: @apply
      COMPLETE: @apply
      ERROR: @apply
      CANCELED : @apply
    @expected = {}
    @requests = 0

  apply: (request) ->
    @expected[request.url()] = @expected[request.url()].filter (status) -> status isnt request.status()
    #@log.info @expected[request.url()]
    expect(@expected[request.url()]).not.contain(request.status())
    @requests-- if @expected[request.url()].length is 0
    if @requests is 0
      @done()

  validate: (url, expected) ->
    @requests++
    @expected[url] = expected

class RejectingExtension extends Extension

  constructor: ->
    super INITIAL: @apply
    @invocations = 0

  apply: (request) ->
    @log.info "Rejecting " + request.url()
    request.cancel("Rejected by RejectingExtension")

class LogStream extends stream.Writable

  constructor: (@target = []) ->
    super

  _write: (chunk, enc, next) ->
    #console.log chunk.toString()
    next()

class ResponseStreamLogger extends Extension

  constructor: ->
    super INITIAL: (request) ->
      request.response.incoming.pipe new LogStream

  apply: (request) ->
    @log.info "Rejecting " + request.url()
    request.cancel("Rejected by RejectingExtension")

class MockContext
  execute: (state, request) -> request
  queue: new QueueManager
  share: (property, value ) =>
    @[property] = value
  crawler :
    enqueue: (request) -> request
  log :
    info : (msg) -> console.log msg
    debug : (msg) -> console.log msg
    error : (msg) -> console.log msg
    trace : (msg) -> console.log msg
    log : (level, msg) -> console.log msg




# https://strongloop.com/strongblog/whats-new-io-js-beta-streams3/
# https://r.va.gg/2014/06/why-i-dont-use-nodes-core-stream-module.html
# Thanks to http://jeroenpelgrims.com/node-streams-in-coffeescript/
# https://github.com/dominictarr/stream-spec
class CharStream extends stream.Readable
  constructor: (@s) ->
    super

  _read: ->
    for c in @s
      @push c
    @push null

class InmemoryStream extends stream.Writable

  constructor: (@target = []) ->
    super

  _write: (chunk, enc, next) ->
    @target.push chunk
    next()

module.exports = {
  RejectingExtension
  TransitionRecorder
  MockContext
  CharStream
  InmemoryStream
  ResponseStreamLogger
}