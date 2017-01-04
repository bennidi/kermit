{Crawler, ext} = require './kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer, ResultVerification} = ext
{RemoteControl} = ext
dircompare = require 'dir-compare'
{obj} = require './util/tools'

describe  'Crawler',  ->
  @timeout 15000
  dir = obj.randomId()
  describe 'integration test for ResourceDiscovery,LocalStorage,OfflineServer', ->
    it '# can transparently route requests to local storage when matching content is found', (done) ->
      Kermit = new Crawler
        name: "testrepo#{dir}"
        basedir : './target/testing/integration'
        autostart: true
        extensions : [
          new ResourceDiscovery
          new AutoShutdown mode:'stop'
          new OfflineStorage
            basedir: "./target/testing/repositories/coffeescript-#{dir}"
          new OfflineServer
            basedir : './fixtures/repositories/coffeescript'
          new ResultVerification
            bad: [ (item, content) -> false ]
            good: [ (item, content) -> true ]
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
                max : 500
              }
            ]
          Filtering:
            allow : [
              /.*coffeescript\.org.*/
            ]
      Kermit.on "crawler:stop", ->
        options =
          compareSize: true
          compareContent: true
          noDiffSet: true
        fixture = './fixtures/repositories/coffeescript/org'
        output = "./target/testing/repositories/coffeescript-#{dir}/org"
        result = dircompare.compareSync fixture, output, options
        expect(result.same).to.be.true()
        done()
      Kermit.crawl "http://coffeescript.org"


