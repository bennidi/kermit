{Status, Crawler, Extension, ext} = require '../cherry.modules.coffee'
{ResourceDiscovery, Statistics, OfflineStorage, OfflineServer} = ext

# opts: rateLimit, request depth
Kermit = new Crawler
  name: "testicle"
  extensions : [
    new Statistics
    new OfflineStorage
    # new OfflineServer
    new ResourceDiscovery
  ]
  options:
    Queueing:
      limits : [
        {
          pattern : /.*jimmycuadra\.com*/
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
        /.*jimmycuadra*/
      ]
      deny : [
      ]

Kermit.schedule("http://www.jimmycuadra.com")


