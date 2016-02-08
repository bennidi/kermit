{Crawler, ext} = require '../kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage} = ext

# opts: rateLimit, item depth
Kermit = new Crawler
  name: "downloader"
  extensions : [
    new OfflineStorage
    new Monitoring
    new ResourceDiscovery
  ]

Kermit.schedule("http://www.reddit.com")


