{Crawler, ext} = require './kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer, ResultVerification} = ext
{RemoteControl} = ext
dircompare = require 'dir-compare'
{obj} = require './util/tools'

describe 'Result verification stops the crawler', ->
  @timeout 15000
  it '#when bad result is found', (done) ->
    Kermit = new Crawler
      name: "testrepo"
      basedir : './target/testing/integration'
      autostart: true
      extensions : [
        new ResourceDiscovery
        new ResultVerification
          bad: [ -> true ]
        new AutoShutdown mode:'shutdown'
        new OfflineServer
          basedir : './fixtures/repositories/coffeescript'
          port: 3001
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
    Kermit.on "commands.stop", ->
      console.log "Test finished"
      done()
    Kermit.crawl "http://coffeescript.org"



