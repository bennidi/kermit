{Crawler, ext} = require './kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer, ResultVerification} = ext
{RemoteControl} = ext
dircompare = require 'dir-compare'
{obj} = require './util/tools'

describe  'Crawler',  ->
  @timeout 5000

  describe 'result verification will stop the crawler', ->
    it '#when bad result is found', (done) ->
      Kermit = new Crawler
        name: "testrepo"
        basedir : './target/testing/integration'
        autostart: true
        extensions : [
          new ResourceDiscovery
          new ResultVerification
            bad: [ (item, content) -> true ]
          new AutoShutdown mode:'shutdown'
          new OfflineServer
            basedir : './fixtures/repositories/coffeescript'
        ]
        options:
          Streaming:
            agentOptions:
              keepAlive:false
          Queueing:
            limits : [
              {
                pattern : /.*coffeescript\.org.*/
                to : 100
                per : 'second'
                max : 50
              }
            ]
          Filtering:
            allow : [
              /.*coffeescript\.org.*/
            ]
      Kermit.on "commands.stop", -> done()
      Kermit.crawl "http://coffeescript.org"



