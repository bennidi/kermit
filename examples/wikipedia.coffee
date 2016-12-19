{Crawler, ext, logconf} = require '../src/kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer, RandomizedDelay} = ext
{RemoteControl} = ext

Kermit = new Crawler
  name: "wikipedia"
  basedir : '/tmp/kermit'
  autostart: true
  extensions : [
    new ResourceDiscovery
    new Monitoring
    new RemoteControl
    new OfflineStorage
      basedir: '/tmp/kermit/wikipedia/content'
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
      filename : '/tmp/kermit/wikipedia'
      limits : [
        {
          pattern :  /.*en.wikipedia\.org.*/
          to : 20
          per : 'second'
          max : 5
        }
      ]
    Filtering:
      allow : [
        /.*en.wikipedia\.org.*/
      ]
      deny : []

Kermit.crawl "http://en.wikipedia.org/wiki/Web_scraping"