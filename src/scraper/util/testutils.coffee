{Extension, ExtensionDescriptor} = require '../Extension.coffee'
{Status} = require '../CrawlRequest.coffee'

class TransitionRecorder extends Extension

  constructor: (@done)->
    super new ExtensionDescriptor "TransitionRecorder", Status.ALL
    @expected = {}
    @requests = 0

  apply: (request) ->
    @expected[request.url()] = @expected[request.url()].filter (status) -> status isnt request.status()
    @log "info", @expected[request.url()]
    expect(@expected[request.url()]).not.contain(request.status())
    @requests-- if @expected[request.url()].length is 0
    if @requests is 0
      @done()

  validate: (url, expected) ->
    @requests++
    @expected[url] = expected

class RejectingExtension extends Extension

  constructor: ->
    super new ExtensionDescriptor "Rejecting Extension", ["INITIAL"]
    @invocations = 0

  apply: (request) ->
    @log "info", "Rejecting " + request.url()
    request.cancel("Rejected by RejectingExtension")

class MockContext
  execute: (state, request) -> request
  queue: contains: () -> false
  crawler :
    enqueue: (request) -> request
  logger :
    info : (msg) -> console.log msg
    debug : (msg) -> console.log msg
    error : (msg) -> console.log msg
    log : (level, msg) -> console.log msg


module.exports = {
  RejectingExtension
  TransitionRecorder
  MockContext
}