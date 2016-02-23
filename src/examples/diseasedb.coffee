{Crawler, ext, logconf} = require '../kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer} = ext

# opts: rateLimit, item depth
Kermit = new Crawler
  name: "diseasedatabase"
  extensions : [
    new ResourceDiscovery
    new Monitoring
    new AutoShutdown
    new Histogrammer
    new OfflineStorage
      basedir: '/ext/dev/scraping/repositories/diseasesdatabase'
    #new OfflineServer
  ]
  options:
    Logging: logconf.detailed
    Streaming:
      agentOptions:
        maxSockets: 15
        keepAlive:true
        maxFreeSockets: 150
        keepAliveMsecs: 1000
    Queueing:
      limits : [
        {
          pattern : /.*diseasesdatabase\.com.*/
          to : 5
          per : 'minute'
          max : 5
        }
      ]
    Filtering:
      allow : [
        /.*diseasesdatabase\.com\/.*/

      ]
# Anything matcing the whitelist will be visited
      deny : [
       # /.*github.*/
        /diseasesdatabase\.com\/index/
        /diseasesdatabase\.com\/begin/
        /diseasesdatabase\.com\/disclaimer/
        /diseasesdatabase\.com\/feedback/
        /diseasesdatabase\.com\/copyright/
        /diseasesdatabase\.com\/snomed/
        /diseasesdatabase\.com\/links/
        /diseasesdatabase\.com\/search_engines/
        /diseasesdatabase\.com\/content/
      ]

Kermit.schedule("http://diseasesdatabase.com/disease_index_a.asp")


