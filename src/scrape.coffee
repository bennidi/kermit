{Crawler} = require './scraper/Crawler.coffee'
{Status} = require './scraper/CrawlRequest.coffee'
{OfflineStorage, OfflineServer} = require './scraper/extensions/ext.offline.coffee'
{ResourceDiscovery} = require './scraper/extensions/ext.discovery.coffee'
{Statistics} = require './scraper/extensions/ext.statistics.coffee'
{Extension} = require './scraper/Extension.coffee'
{WithinDomain, MimeTypes, ByUrl} = require './scraper/extensions/core.filter.coffee'

# opts: rateLimit, request depth
Crawler = new Crawler
  name: "testicle"
  extensions : [
    new Statistics
    new OfflineStorage
    new OfflineServer
    new ResourceDiscovery
  ]
  options:
    Queueing:
      limits : [
        {
          pattern : /.*jimmycuadra\.com*/
          to : 20
          per : 'second'
          max : 20
        }
      ]
    Filtering:
      allow : [
        /.*jimmycuadra*/
      ]
      deny : [
      ]

Crawler.schedule("http://www.jimmycuadra.com")


