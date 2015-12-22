{Extension} = require '../Extension.coffee'
{Status} = require '../CrawlRequest.coffee'
{QueueManager} = require '../QueueManager.coffee'
through = require 'through2'
stream = require 'stream'

# Record status transitions of all requests and assert the a specified series of
# transitions has been made
class TransitionRecorder extends Extension

  # @nodoc
  constructor: (@done)->
    super
      INITIAL: (request) -> @apply request, 'INITIAL'
      SPOOLED: (request) -> @apply request, 'SPOOLED'
      READY: (request) -> @apply request, 'READY'
      FETCHING: (request) -> @apply request, 'FETCHING'
      FETCHED: (request) -> @apply request, 'FETCHED'
      COMPLETE: (request) -> @apply request, 'COMPLETE'
      ERROR: (request) -> @apply request, 'ERROR'
      CANCELED : (request) -> @apply request, 'CANCELED'
    @expected = {}
    @requests = 0

  # @nodoc
  apply: (request, status) ->
    @expected[request.url()] = @expected[request.url()].filter (expected) -> expected isnt status
    @log.info? "Expected for #{request.url()}: #{@expected[request.url()]}"
    expect(@expected[request.url()]).not.contain(status)
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
    @log.info? "Rejecting " + request.url()
    request.cancel("Rejected by RejectingExtension")

class MockContext
  execute: (state, request) -> request
  config:
    basePath : () -> "somepath"
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

module.exports = {
  RejectingExtension
  TransitionRecorder
  MockContext
}