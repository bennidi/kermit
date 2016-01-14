{Status} = require('../CrawlRequest')
{MemoryStream} = require('../util/tools.coffee')
{Mimetypes} = require('../Pipeline.coffee')
{Extension} = require '../Extension'
URI = require 'urijs'
validUrl = require 'valid-url'
url = require 'url'
_ = require 'lodash'
htmlToJson = require 'html-to-json'


# Scan result data for links to other resources (css, img, js, html) and schedule
# a request to retrieve those resources.
class ResourceDiscovery extends Extension

  @defaultOpts: () ->
    links : true
    anchors: true
    scripts: true # TODO: implement discovery
    images : true # TODO: implement discovery

  # Create a new resource discovery extension
  constructor: (@opts = {}) ->
    @content = {}
    @opts = @merge ResourceDiscovery.defaultOpts(), @opts
    super
      READY : (request) =>
        target = @content[request.id()] = []
        request.response.stream Mimetypes( [/.*html.*/g] ), new MemoryStream target
      FETCHED : (request) =>
        input = @contents request
        selectors =
          resources: ['link',
            'href':  ($section) -> $section.attr 'href'
          ]
          links: ['a',
            'href':  ($link) -> $link.attr 'href'
          ]
        extractors = (error, results) =>
          resources = _.reject (@cleanUrl request, url.href for url in results.filter.resources), _.isEmpty
          links = _.reject (@cleanUrl request, url.href for url in results.filter.links), _.isEmpty
          @context.schedule request, url for url in resources
          @context.schedule request, url for url in links
          delete @content[request.id()] # free the memory
        if not _.isEmpty input
          htmlToJson.batch input, htmlToJson.createParser(selectors), extractors



  contents: (request) ->
    data = @content[request.id()]
    if data.length > 1 then data.join "" else data[0]

  cleanUrl: (request, url)  =>
    base = request.uri()
    cleaned = url
    if cleaned
      # Handle //de.wikinews.org/wiki/Hauptseite
      cleaned = url.replace /\/\//g, base.scheme() + "://" if cleaned.startsWith "//"
      # Handle relative urls with leading slash, i.e. /wiki/Hauptseite
      cleaned = URI(url).absoluteTo(base.toString()).toString() if cleaned.startsWith "/"
      # Drop in-page anchors, i.e. #info or self references, i.e. "/"
      cleaned = "" if url.startsWith("#") or url is "/"
      @log.debug? "#{url} -> #{cleaned} in #{base}", tags:['Discovery']
    else
      @log.debug? "Invalid url in #{base}", tags:['Discovery']
      cleaned = ""
    cleaned

module.exports = {ResourceDiscovery}