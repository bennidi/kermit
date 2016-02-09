{Crawler, ext, logconf} = require '../kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer} = ext

# opts: rateLimit, item depth
Kermit = new Crawler
  name: "testicle"
  extensions : [
    new Monitoring
    new OfflineStorage
    new AutoShutdown
    new Histogrammer
    # new OfflineServer
    new ResourceDiscovery
  ]
  options:
    Logging: logconf.detailed
    Queueing:
      limits : [
        {
          pattern : /.*jimmycuadra\.com.*/
          to : 5
          per : 'second'
          max : 10
        }
      ]
    Filtering:
      allow : [
        #/.*jimmycuadra\.com.*/
        /.*\.jimmycuadra\.com/
      ]
      deny : [
        /.*\.jimmycuadra\.com\/.+/
      ]

Kermit.schedule("http://www.jimmycuadra.com")


