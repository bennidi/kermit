cherry = require './cherry.modules'
Status = cherry.requests.Status

describe  'Crawler',  ->
  describe 'package', ->

    it '# extensions are called for specific phases', (done)->
      Recorder = new TransitionRecorder done
      SimpleCrawler = new cherry.Crawler extensions : [Recorder]
      npmRequest = SimpleCrawler.enqueue("http://www.npmjs.com")
      Recorder.validate(npmRequest, [Status.INITIAL,Status.SPOOLED, Status.READY, Status.FETCHING])



    it '# extensions can prevent a request from being processed', (done)->
      Recorder = new TransitionRecorder done
      SimpleCrawler = new cherry.Crawler extensions : [new RejectingExtension]
      npmRequest = SimpleCrawler.enqueue("http://www.npm.com")
      githubRequest = SimpleCrawler.enqueue("http://www.github.com")
      Recorder.validate(npmRequest, [Status.INITIAL,Status.CANCELED])
      Recorder.validate(githubRequest, [Status.INITIAL,Status.CANCELED])



    it '# allows to schedule follow-up requests', (done) ->
      Recorder = new TransitionRecorder done
      SimpleCrawler = new cherry.Crawler core : RequestFilter : maxDepth : 1
      npmRequest = SimpleCrawler.enqueue("http://www.npm.com")
      browserify = npmRequest.enqueue("package/browserify")
      Recorder.validate(npmRequest, [Status.INITIAL,Status.SPOOLED, Status.READY,
                                     Status.FETCHING, Status.FETCHED, Status.COMPLETE])
      Recorder.validate(browserify, [Status.INITIAL,Status.SPOOLED, Status.READY,
                                        Status.FETCHING, Status.FETCHED, Status.COMPLETE])

class TransitionRecorder extends cherry.extensions.Extension

  constructor: (@done)->
    super new cherry.extensions.ExtensionDescriptor "TransitionRecorder", [Status.INITIAL]
    @transitions = {}
    @count = 0

  getTransitions: (request) ->
    if !@transitions[request.id()]
      @transitions[request.id()] = [Status.INITIAL]
    @transitions[request.id()]

  propagateChange: (request) ->
    @getTransitions(request).push request.status()

  apply: (request) ->
    request.onStatus( status, (request) => @propagateChange(request)) for status in Status.ALL

  validate: (request, expected) ->
    @count++
    lastState = expected[-1 + expected.length]
    request.onStatus lastState, (request) =>
      @done() if --@count is 0
      expect(@getTransitions(request)).to.contain(expectedState) for expectedState in expected

class RejectingExtension extends cherry.extensions.Extension

  constructor: ->
    super new cherry.extensions.ExtensionDescriptor "Rejecting Extension", ["INITIAL"]
    @invocations = 0

  apply: (request) ->
    request.cancel()
