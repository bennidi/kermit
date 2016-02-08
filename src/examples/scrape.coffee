{Crawler, ext, logconf} = require '../kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer} = ext

# opts: rateLimit, item depth
Kermit = new Crawler
  name: "testicle"
  extensions : [
    new Monitoring
    new OfflineStorage
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
        /.*jimmycuadra.*/
      ]
      deny : [
        /.*return_to.*/
      ]

Kermit.schedule("http://www.jimmycuadra.com")


