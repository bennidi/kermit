{Crawler} = require './scraper/Crawler.coffee'
{Status} = require './scraper/CrawlRequest.coffee'
{OfflineStorage, OfflineServer} = require './scraper/extensions/plugin.offline.coffee'
{ResourceDiscovery} = require './scraper/extensions/ext.resource.discovery.coffee'
{Extension} = require './scraper/Extension.coffee'
{WithinDomain, MimeTypes, ByUrl} = require './scraper/extensions/core.filter.coffee'

# opts: rateLimit, request depth
Crawler = new Crawler
  name: "testicle"
  extensions : [
    #new OfflineStorage
    new  ResourceDiscovery
  ]
  options:
    Queueing:
      limits : [
        {
          pattern : ".*jimmycuadra.com.*"
          to : 10
          per : 'second'
          max : 10
        }
        {
          pattern : "https.*github.*"
          to : 10
          per : 'second'
          max : 10
        }
      ]
    Filtering:
      allow : [
        /.*jimmycuadra.*/g
      ]
      deny : [
        /.*login.*/g
        #ByUrl 'https'
      ]

Crawler.enqueue("http://jimmycuadra.com")


