{Crawler, ext, logconf} = require '../kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer, RandomizedDelay} = ext
{RemoteControl} = ext

# opts: rateLimit, item depth
Kermit = new Crawler
  name: "testrepo"
  basedir : '/tmp/kermit'
  autostart: true
  extensions : [
    new ResourceDiscovery
    new Monitoring
    #new AutoShutdown
    #new Histogrammer
    new RemoteControl
    new RandomizedDelay
      delays: [
        ratio: 1
        interval: 10000
        duration: 30000
      ]
    new OfflineStorage
      basedir: '/tmp/kermit/wikipedia2'
    #new OfflineServer
    #  basedir : '/ext/dev/workspace/webcherries/testing/repo-coffeescript'
  ]
  options:
    Logging: logconf.production
    Streaming:
      agentOptions:
        maxSockets: 15
        keepAlive:true
        maxFreeSockets: 150
        keepAliveMsecs: 1000
    Queueing:
      filename : '/tmp/kermit/testrepo/wikipedia2'
      limits : [
        {
          pattern :  /.*en.wikipedia\.org.*/
          to : 1
          per : 'second'
          max : 1
        }
      ]
    Filtering:
      allow : [
        /.*en.wikipedia\.org.*/
      ]
# Anything matching the whitelist will be visited
      deny : [
      ]


Kermit.execute "http://en.wikipedia.org/wiki/Web_scraping"