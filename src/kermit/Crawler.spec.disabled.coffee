{Crawler} = require './Crawler'
{RejectingExtension, TransitionRecorder, ResponseStreamLogger} = require './util/spec.utils'
{ResponseStreamLogger} = require './util/spec.utils'
{Phase} = require './RequestItem.Phases'
{ByPattern} = require './extensions/core.filter'
{obj} = require './util/tools'

describe  'Crawler',  ->
  @timeout 3000
  describe 'package', ->
    Kermit = null


    it '# can be instantiated with options for core extensions', ->
      Kermit = new Crawler
        name: "testicle"
        basedir: "./target"
        options:
          Queueing:
            limits : [
              pattern : /.*coffeescript\.org/,
              to : 1,
              per : 'minute'
            ]
            filename: obj.randomId()
          Filtering:
            allow : [
              ByPattern /.*coffeescript\.org/
            ]
      Kermit.stop()

    ###
    it '# extensions can prevent an item from being processed', (done)->
      Recorder = new TransitionRecorder -> Kermit.stop();done()
      Recorder.validate("http://www.google.com/", [Phase.INITIAL])
      Recorder.validate("http://www.github.com/", [Phase.INITIAL])
      Kermit = new Crawler
        name : "Test Item Rejection"
        basedir: "./target"
        extensions : [Recorder, new RejectingExtension, new ResponseStreamLogger]
      Kermit.execute("http://www.google.com")
      Kermit.execute("http://www.github.com")###



