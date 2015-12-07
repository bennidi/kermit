sloth = require './scraper/cherry.modules'
{Status} = require './scraper/CrawlRequest.coffee'
{OfflineStorage, OfflineServer} = require './scraper/extensions/plugin.offline.coffee'
{ResourceDiscovery} = require './scraper/extensions/ext.resource.discovery.coffee'
{Extension, ExtensionDescriptor} = require './scraper/Extension.coffee'
{WithinDomain, MimeTypes} = require './scraper/extensions/core.filter.coffee'

# opts: rateLimit, request depth
Crawler = new sloth.Crawler
  name: "testicle"
  extensions : [
    new OfflineStorage
      basedir : ""
    new  ResourceDiscovery
      scripts:false
      links:false]
  options:
    Queue:
      limits : [
        domain : ".*stackoverflow.com.*",
        to : 5,
        per : 'second'
      ]
    Filter:
      allow : [
        WithinDomain "stackoverflow"
      ]
      deny : [
        (request) -> request.depth() > 1 and not WithinDomain("stackoverflow")(request)
      ]

Crawler.enqueue("http://stackoverflow.com/questions/20931089/winston-understanding-logging-levels")


