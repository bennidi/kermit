{Status} = require('../CrawlRequest')
{HtmlProcessor} = require './ext.htmlprocessor.coffee'
URI = require 'urijs'
_ = require 'lodash'
{HtmlExtractor} = require '../Extractor.coffee'
tools = require '../util/tools.coffee'


# Scan result data for links to other resources (css, img, js, html) and schedule
# a request to retrieve those resources.
class ResourceDiscovery extends HtmlProcessor

  @defaultOpts: () ->
    links : true
    anchors: true
    scripts: true # TODO: implement discovery
    images : true # TODO: implement discovery

  # Create a new resource discovery extension
  constructor: () ->
    @opts = @merge ResourceDiscovery.defaultOpts(), @opts
    super [
      new HtmlExtractor
        name : 'all'
        select :
          resources: ['link',
            'href':  ($section) -> $section.attr 'href'
          ]
          links: ['a',
            'href':  ($link) -> $link.attr 'href'
          ]
        onResult : (results, request) =>
          resources = _.reject (@cleanUrl request, url.href for url in results.resources), _.isEmpty
          links = _.reject (@cleanUrl request, url.href for url in results.links), _.isEmpty
          @context.schedule url, parents:request.parents()+1  for url in resources
          @context.schedule url, parents:request.parents()+1  for url in links
    ]

  cleanUrl: (request, url)  =>
    base = URI request.url()
    cleaned = url
    if cleaned
      # Handle //de.wikinews.org/wiki/Hauptseite
      cleaned = url.replace /\/\//g, base.scheme() + "://" if cleaned.startsWith "//"
      # Handle relative urls with leading slash, i.e. /wiki/Hauptseite
      cleaned = URI(url).absoluteTo(base).toString() if cleaned.startsWith "/"
      # Drop in-page anchors, i.e. #info or self references, i.e. "/"
      cleaned = "" if url.startsWith("#") or url is "/" or url.startsWith("mailto")
    else
      @log.debug? "Invalid url in #{base}", tags:['Discovery']
      cleaned = ""
    tools.uri.normalize cleaned

module.exports = {ResourceDiscovery}