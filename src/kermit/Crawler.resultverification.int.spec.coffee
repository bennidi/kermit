{Crawler, ext} = require './kermit.modules.coffee'
{ResourceDiscovery,OfflineServer,
ResultVerification, NotificationCenter,
FullRequestTrace, Monitoring, OfflineStorage} = ext
dircompare = require 'dir-compare'
{obj} = require './util/tools'

describe 'Result verification stops the crawler', ->
  @timeout 15000
  it '#when bad result is found', (done) ->
    dir = obj.randomId()
    count = 1
    counter = ->
      count++ < 20 and count % 3 is 0
    Kermit = new Crawler
      name: "resultcheck#{dir}"
      basedir : './target/testing/integration'
      autostart: yes
      extensions : [
        new FullRequestTrace
        new Monitoring interval:500
        new NotificationCenter
        new ResourceDiscovery
        new OfflineStorage
          basedir: "./target/testing/repositories/resultcheck/#{dir}"
        new ResultVerification
          bad: [ counter ]
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

    Kermit.on "crawler:stopped", ->
      if Kermit.hasWork()
        Kermit.start()
      else
        options =
          compareSize: true
          compareContent: true
          noDiffSet: true
        fixture = './fixtures/repositories/coffeescript/org'
        output = "./target/testing/repositories/resultcheck/#{dir}/org"
        result = dircompare.compareSync fixture, output, options
        #expect(result.same).to.be.true()
        done()
    Kermit.crawl "http://coffeescript.org"



