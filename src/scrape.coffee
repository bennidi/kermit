cherry = require './scraper/cherry.modules'
Status = cherry.requests.Status


Crawler = new cherry.Crawler
  extensions : [new cherry.extensions.Filter ,
                new cherry.extensions.ResourceDiscovery]
Crawler.enqueue("https://de.wikipedia.org/wiki/Wikipedia:Hauptseite")

setTimeout console.log, 60000