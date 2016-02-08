{Crawler} = require './Crawler'
{RejectingExtension, TransitionRecorder, ResponseStreamLogger} = require './util/spec.utils'
{ResponseStreamLogger} = require './util/spec.utils'
{Phase} = require './RequestItem'
{ByPattern} = require './extensions/core.filter'

describe  'Crawler',  ->
  @timeout 3000
  describe 'package', ->
    Kermit = null
    it '# can be instantiated without any options', ()->
      Kermit = new Crawler
      expect(Kermit).to.be.a(Crawler)
      Kermit.shutdown()
  
    it '# can be instantiated with options for core extensions', ()->
      Kermit = new Crawler
        name: "testicle"
        options:
          Queueing:
            limits : [
              pattern : /.*jimmycuadra.com.*/,
              to : 1,
              per : 'minute'
            ]
          Filtering:
            allow : [
              ByPattern /.*jimmycuadra.*/
            ]
      Kermit.shutdown()  
      
    it '# extensions are called for specific phases', (done)->
      Recorder = new TransitionRecorder () -> done(); Kermit.shutdown()
      Recorder.validate("http://www.google.com/", [Phase.INITIAL,Phase.SPOOLED, Phase.READY,
        Phase.FETCHING, Phase.FETCHED, Phase.COMPLETE])
      Kermit = new Crawler extensions : [Recorder, new ResponseStreamLogger]
      Kermit.execute("http://www.google.com")


    it '# extensions can prevent a item from being processed', (done)->
      Recorder = new TransitionRecorder () -> done(); Kermit.shutdown()
      Recorder.validate("http://www.google.com/", [Phase.INITIAL])
      Recorder.validate("http://www.github.com/", [Phase.INITIAL])
      Kermit = new Crawler extensions : [Recorder, new RejectingExtension, new ResponseStreamLogger]
      Kermit.execute("http://www.google.com")
      Kermit.execute("http://www.github.com")



