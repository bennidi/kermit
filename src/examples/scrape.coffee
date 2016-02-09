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
  ]
  options:
    Logging: logconf.detailed
    Queueing:
      limits : [
        {
          pattern : /.*jimmycuadra\.com.*/
          to : 3
          per : 'second'
          max : 5
        }
      ]
    Filtering:
      allow : [
        /.*jimmycuadra\.com.*/
      ]
# Anything matcing the whitelist will be visited
      deny : [
       # /.*github.*/
      ]

Kermit.schedule("http://jimmycuadra.com")


