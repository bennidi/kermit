cherry = require './scraper/cherry.modules'
Status = cherry.requests.Status
{OfflineStorage, OfflineServer} = require './scraper/extensions/plugin.offline.coffee'
{ResourceDiscovery} = require './scraper/extensions/ext.resource.discovery.coffee'
{Extension, ExtensionDescriptor} = require './scraper/Extension.coffee'
{WithinDomain, MimeTypes} = require './scraper/extensions/core.filter.coffee'


class ResponseLogger extends Extension

  constructor: () ->
    super new ExtensionDescriptor 'Logger', ['COMPLETED'], "Blubb"

  apply: (request) ->
    console.log request.body.substring(200)

# opts: rateLimit, request depth
Crawler = new cherry.Crawler
  extensions : [
    new OfflineStorage,
    new  ResourceDiscovery
      scripts:false
      links:false]
  options:
    Queue:
      limits : [
        domain : ".*jimmycuadra.com.*",
        to : 5,
        per : 'second'
      ]
    Filter:
      allow : [
        WithinDomain "jimmycuadra"
      ]
      deny : [
        (request) -> request.depth() > 1 and not WithinDomain("jimmycuadra")(request)
      ]

Crawler.enqueue("http://www.jimmycuadra.com/")

setTimeout Crawler.shutdown, 60000