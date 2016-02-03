{Phase, Crawler, Extension, ext, logconf} = require '../kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer} = ext

# opts: rateLimit, request depth
Kermit = new Crawler
  name: "testicle"
  extensions : [
    new Monitoring
    new OfflineStorage
    # new OfflineServer
    new ResourceDiscovery
  ]
  options:
    Logging: logconf.basic
    Queueing:
      limits : [
        {
          pattern : /.*jimmycuadra\.com.*/
          to : 20
          per : 'second'
          max : 10
        }
        {
          pattern : /.*/
          to : 20
          per : 'second'
          max : 10
        }
      ]
    Filtering:
      allow : [
        /.*jimmycuadra.*/
      ]
      deny : []

Kermit.schedule("http://www.jimmycuadra.com")


