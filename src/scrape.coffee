{Crawler} = require './scraper/Crawler.coffee'
{Status} = require './scraper/CrawlRequest.coffee'
{OfflineStorage, OfflineServer} = require './scraper/extensions/plugin.offline.coffee'
{ResourceDiscovery} = require './scraper/extensions/ext.resource.discovery.coffee'
{Extension} = require './scraper/Extension.coffee'
{WithinDomain, MimeTypes} = require './scraper/extensions/core.filter.coffee'

# opts: rateLimit, request depth
Crawler = new Crawler
  name: "testicle"
  extensions : [
    new OfflineStorage
    #new OfflineServer
    #  basedir : ""
    new  ResourceDiscovery
      scripts:false
      links:false]
  options:
    Queueing:
      limits : [
        domain : ".*jimmycuadra.com.*",
        to : 5,
        per : 'second'
      ]
    Filtering:
      allow : [
        WithinDomain "jimmycuadra"
      ]

Crawler.enqueue("http://jimmycuadra.com")


