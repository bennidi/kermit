cherry = require './scraper/cherry.modules'
Status = cherry.requests.Status


# opts: rateLimit, request depth
Crawler = new cherry.Crawler
  extensions : [new cherry.extensions.Filter ,
                new cherry.extensions.ResourceDiscovery,
                new cherry.extensions.OfflineStorage]
Crawler.enqueue("http://www.jimmycuadra.com/")

setTimeout console.log, 60000