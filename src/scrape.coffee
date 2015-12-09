sloth = require './scraper/cherry.modules'
{Status} = require './scraper/CrawlRequest.coffee'
{OfflineStorage, OfflineServer} = require './scraper/extensions/plugin.offline.coffee'
{ResourceDiscovery} = require './scraper/extensions/ext.resource.discovery.coffee'
{Extension} = require './scraper/Extension.coffee'
{WithinDomain, MimeTypes} = require './scraper/extensions/core.filter.coffee'

class ResponseLogger extends Extension

  constructor:() ->
    super "ResponseLogger", [Status.FETCHED]

  apply: (request) ->
    console.log request.body

# opts: rateLimit, request depth
Crawler = new sloth.Crawler
  name: "testicle"
  extensions : [
    new ResponseLogger
    new OfflineServer
      basedir : ""
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
        (request) -> request.predecessors() > 1 and not WithinDomain("jimmycuadra")(request)
      ]

Crawler.enqueue("http://jimmycuadra.com")


