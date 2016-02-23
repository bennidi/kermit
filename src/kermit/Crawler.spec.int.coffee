{Crawler, ext} = require './kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer, RandomizedDelay} = ext
{RemoteControl} = ext

describe  'Crawler',  ->
  @timeout 15000
  describe 'integration test for ResourceDiscovery,LocalStorage,OfflineServer', ->
    it '# can be instantiated with options for core extensions', (done) ->
      Kermit = new Crawler
        name: "testrepo"
        basedir : '/tmp/kermit'
        autostart: true
        extensions : [
          new ResourceDiscovery
          new AutoShutdown
          new OfflineStorage
            basedir: './target/testing/repo-coffeescript'
          new OfflineServer
            basedir : './testing/repo-coffeescript'
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
      Kermit.context.messenger.subscribe "commands.stop", ->
        done()
      Kermit.execute "http://coffeescript.org"



