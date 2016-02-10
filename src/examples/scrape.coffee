{Crawler, ext, logconf} = require '../kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer} = ext

# opts: rateLimit, item depth
Kermit = new Crawler
  name: "testicle"
  extensions : [
    new ResourceDiscovery
    new Monitoring
    new AutoShutdown
    new Histogrammer
    new OfflineStorage
    #new OfflineServer
  ]
  options:
    Logging: logconf.detailed
    Streaming:
      agentOptions:
        maxSockets: 15
        keepAlive:true
        maxFreeSockets: 150
        keepAliveMsecs: 3000
    Queueing:
      limits : [
        {
          pattern : /.*en.wikipedia\.org.*/
          to : 3
          per : 'second'
          max : 20
        }
      ]
    Filtering:
      allow : [
        /.*en.wikipedia\.org.*/
      ]
# Anything matcing the whitelist will be visited
      deny : [
       # /.*github.*/
      ]

Kermit.schedule("http://en.wikipedia.org")


