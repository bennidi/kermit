cherry = require './cherry.modules'
{RejectingExtension, TransitionRecorder, ResponseStreamLogger} = require './util/spec.utils.coffee'
{ResponseStreamLogger} = require './util/utils.coffee'
{Status} = require './CrawlRequest.coffee'

describe  'Crawler',  ->
  @timeout 6000
  describe 'package', ->
    Kermit = null
    it '# can be instantiated without any options', ()->
      Kermit = new cherry.Crawler
      expect(Kermit).to.be.a(cherry.Crawler)
      Kermit.shutdown()

    it '# extensions are called for specific phases', (done)->
      Recorder = new TransitionRecorder () -> done(); Kermit.shutdown()
      Recorder.validate("http://www.google.com/", [Status.INITIAL,Status.SPOOLED, Status.READY,
        Status.FETCHING, Status.FETCHED, Status.COMPLETE])
      Kermit = new cherry.Crawler extensions : [Recorder, new ResponseStreamLogger]
      Kermit.enqueue("http://www.google.com")


    it '# extensions can prevent a request from being processed', (done)->
      Recorder = new TransitionRecorder () -> done(); Kermit.shutdown()
      Recorder.validate("http://www.google.com/", [Status.INITIAL])
      Recorder.validate("http://www.github.com/", [Status.INITIAL])
      Kermit = new cherry.Crawler extensions : [Recorder, new RejectingExtension, new ResponseStreamLogger]
      Kermit.enqueue("http://www.google.com")
      Kermit.enqueue("http://www.github.com")


    it '# allows to schedule follow-up requests', (done) ->
      Recorder = new TransitionRecorder () -> done(); Kermit.shutdown()
      Recorder.validate("http://www.google.com/", [Status.INITIAL,Status.SPOOLED, Status.READY,
        Status.FETCHING, Status.FETCHED, Status.COMPLETE])
      Recorder.validate("http://www.wikipedia.org/", [Status.INITIAL,Status.SPOOLED, Status.READY,
        Status.FETCHING, Status.FETCHED, Status.COMPLETE])
      Kermit = new cherry.Crawler
          extensions : [Recorder, new ResponseStreamLogger]
      Kermit.enqueue("http://www.google.com/").enqueue("http://www.wikipedia.org/")



