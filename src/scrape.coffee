cherry = require './scraper/cherry.modules'
Status = cherry.requests.Status
{OfflineStorage, OfflineServer} = require './scraper/extensions/plugin.offline.coffee'
ResourceDiscovery = require './scraper/extensions/ext.resource.discovery.coffee'
{Extension, ExtensionDescriptor} = require './scraper/Extension.coffee'

class ResponseLogger extends Extension

  constructor: () ->
    super new ExtensionDescriptor 'Logger', ['COMPLETE'], "Blubb"

  apply: (request) ->
    console.log request.body

# opts: rateLimit, request depth
Crawler = new cherry.Crawler
  extensions : [ new OfflineServer, new  ResourceDiscovery ]
  core:
    RequestFilter:
      maxDepth : 4
Crawler.enqueue("http://www.jimmycuadra.com/")

setTimeout Crawler.shutdown, 60000