{Status} = require('../CrawlRequest')
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
    super
      READY : (request) ->
        request.response.parser().extract(
          resources: ['link',
            'href':  ($section) -> $section.attr 'href'
          ]
          links: ['a',
            'href':  ($link) -> $link.attr 'href'
          ]).then (results) =>
            resources = _.reject (@cleanUrl request, url.href for url in results.resources), _.isEmpty
            links = _.reject (@cleanUrl request, url.href for url in results.links), _.isEmpty
            request.enqueue url for url in resources
            request.enqueue url for url in links
    @opts = @merge ResourceDiscovery.defaultOpts(), @opts

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