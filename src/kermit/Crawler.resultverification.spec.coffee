{Crawler, ext} = require './kermit.modules.coffee'
{ResourceDiscovery,OfflineServer,  ResultVerification, NotificationCenter} = ext

describe 'Result verification stops the crawler', ->
  @timeout 15000
  it '#when bad result is found', (done) ->
    Kermit = new Crawler
      name: "testrepo"
      basedir : './target/testing/integration'
      autostart: true
      extensions : [
        new NotificationCenter
        new ResourceDiscovery
        new ResultVerification
          bad: [ -> true ]
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
    Kermit.on "crawler:stop", ->
      console.log "#####################################################Test finished: resultverificatoin"
      done()
    Kermit.crawl "http://coffeescript.org"



