cherry = require './scraper/cherry.modules'
Status = cherry.requests.Status
{OfflineStorage, OfflineServer} = require './scraper/extensions/plugin.offline.coffee'
ResourceDiscovery = require './scraper/extensions/ext.resource.discovery.coffee'
{Extension, ExtensionDescriptor} = require './scraper/Extension.coffee'
{ByDomain, MimeTypes} = require './scraper/extensions/core.filter.coffee'


class ResponseLogger extends Extension

  constructor: () ->
    super new ExtensionDescriptor 'Logger', ['COMPLETE'], "Blubb"

  apply: (request) ->
    console.log request.body

# opts: rateLimit, request depth
Crawler = new cherry.Crawler
  extensions : [ new OfflineServer, new  ResourceDiscovery ]
  options:
    Filter:
      allow : [
        WithinDomain ""
      ]
      deny : [
        (request) -> request.depth() > 1 and not WithinDomain("jimmycuadra")(request)
      ]


Crawler.enqueue("http://www.jimmycuadra.com/")

setTimeout Crawler.shutdown, 60000