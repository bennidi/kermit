cherry = require './cherry.modules'
{RejectingExtension, TransitionRecorder, ResponseStreamLogger} = require './util/testutils.coffee'
{Status} = require './CrawlRequest.coffee'

describe  'Crawler',  ->
  @timeout 3000
  describe 'package', ->

    it '# can be instantiated without any options', ()->
      SimpleCrawler = new cherry.Crawler
      expect(SimpleCrawler).to.be.a(cherry.Crawler)

    it '# can be instantiated with options for specific extensions', ()->
      SimpleCrawler = new cherry.Crawler
        options :
          Streamer:
            userAgent : "Custom user agent"
      expect(SimpleCrawler).to.be.a(cherry.Crawler)

    it '# extensions are called for specific phases', (done)->
      Recorder = new TransitionRecorder done
      Recorder.validate("http://www.google.com/", [Status.INITIAL,Status.SPOOLED, Status.READY,
        Status.FETCHING, Status.FETCHED, Status.COMPLETE])
      SimpleCrawler = new cherry.Crawler extensions : [Recorder, new ResponseStreamLogger]
      SimpleCrawler.enqueue("http://www.google.com")


    it '# extensions can prevent a request from being processed', (done)->
      Recorder = new TransitionRecorder done
      Recorder.validate("http://www.google.com/", [Status.INITIAL])
      Recorder.validate("http://www.github.com/", [Status.INITIAL])
      SimpleCrawler = new cherry.Crawler extensions : [Recorder, new RejectingExtension, new ResponseStreamLogger]
      SimpleCrawler.enqueue("http://www.google.com")
      SimpleCrawler.enqueue("http://www.github.com")


    it '# allows to schedule follow-up requests', (done) ->
      Recorder = new TransitionRecorder done
      Recorder.validate("http://www.google.com/", [Status.INITIAL,Status.SPOOLED, Status.READY,
        Status.FETCHING, Status.FETCHED, Status.COMPLETE])
      Recorder.validate("http://www.wikipedia.org/", [Status.INITIAL,Status.SPOOLED, Status.READY,
        Status.FETCHING, Status.FETCHED, Status.COMPLETE])
      SimpleCrawler = new cherry.Crawler
          extensions : [Recorder, new ResponseStreamLogger]
      SimpleCrawler.enqueue("http://www.google.com/").enqueue("http://www.wikipedia.org/")



