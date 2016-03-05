{Crawler, ext} = require './kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer, RandomizedDelay} = ext
{RemoteControl} = ext
dircompare = require 'dir-compare'
{obj} = require './util/tools'

describe  'Crawler',  ->
  @timeout 15000
  dir = obj.randomId()
  describe 'integration test for ResourceDiscovery,LocalStorage,OfflineServer', ->
    it '# can be instantiated with options for core extensions', (done) ->
      Kermit = new Crawler
        name: "testrepo"
        basedir : './target/testing/integration'
        autostart: true
        extensions : [
          new ResourceDiscovery
          new AutoShutdown mode:'stop'
          new OfflineStorage
            basedir: "./target/testing/repositories/coffeescript-#{dir}"
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
      Kermit.on "commands.stop", ->
        options =
          compareSize: true
          noDiffSet: true
        fixture = './fixtures/repositories/coffeescript/org'
        output = "./target/testing/repositories/coffeescript-#{dir}/org"
        result = dircompare.compareSync fixture, output, options
        expect(result.same).to.be.true()
        done()
      Kermit.execute "http://coffeescript.org"



