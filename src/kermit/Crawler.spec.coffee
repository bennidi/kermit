{Crawler} = require './Crawler'
{RejectingExtension, TransitionRecorder, ResponseStreamLogger} = require './util/spec.utils'
{ResponseStreamLogger} = require './util/spec.utils'
{Phase} = require './RequestItem.Phases'
{ByPattern} = require './extensions/core.filter'

describe  'Crawler',  ->
  @timeout 3000
  describe 'package', ->
    Kermit = null
    it '# can be instantiated without any options', ()->
      Kermit = new Crawler
      expect(Kermit).to.be.a(Crawler)
      Kermit.stop()
  
    it '# can be instantiated with options for core extensions', ()->
      Kermit = new Crawler
        name: "testicle"
        options:
          Queueing:
            limits : [
              pattern : /.*coffeescript\.org/,
              to : 1,
              per : 'minute'
            ]
          Filtering:
            allow : [
              ByPattern /.*coffeescript\.org/
            ]
      Kermit.stop()


    it '# extensions can prevent an item from being processed', (done)->
      Recorder = new TransitionRecorder -> done(); Kermit.stop()
      Recorder.validate("http://www.google.com/", [Phase.INITIAL])
      Recorder.validate("http://www.github.com/", [Phase.INITIAL])
      Kermit = new Crawler extensions : [Recorder, new RejectingExtension, new ResponseStreamLogger]
      Kermit.execute("http://www.google.com")
      Kermit.execute("http://www.github.com")



