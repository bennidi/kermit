{Status} = require('../CrawlRequest')
{Extension, ExtensionDescriptor} = require '../Extension'
URI = require 'urijs'
validUrl = require 'valid-url'
url = require 'url'
_ = require 'lodash'
htmlToJson = require 'html-to-json'

# Scan result data for links to other resources (css, img, js, html) and schedule
# a request to retrieve those resources.
class ResourceDiscovery extends Extension

  # http://elijahmanor.com/regular-expressions-in-coffeescript-are-awesome/
  # https://coffeescript-cookbook.github.io/chapters/regular_expressions/searching-for-substrings
  # http://stackoverflow.com/questions/1500260/detect-urls-in-text-with-javascript
  @defaultOpts =
    links : true
    anchors: true
    scripts: true # TODO: implement discovery
    images : true # TODO: implement discovery



  constructor: (@opts = ResourceDiscovery.defaultOpts) ->
    super new ExtensionDescriptor "ResourceDiscovery", [Status.FETCHED]
    @opts = Extension.mergeOptions ResourceDiscovery.defaultOpts, @opts

  apply: (request) ->
    extractLinks request.body, (results) ->
      resources = _.reject (cleanUrl.call(this, request.uri(), url.href) for url in results.filter.resources), _.isEmpty
      links = _.reject (cleanUrl.call(this, request.uri(), url.href) for url in results.filter.links), _.isEmpty
      request.enqueue url for url in resources
      request.enqueue url for url in links


  # Run a htmlToJson extractor
  extractLinks = (html, handler) ->
    htmlToJson.batch(html,
      htmlToJson.createParser
        resources: ['link',
          'href':  ($section) -> $section.attr 'href'
        ]
        links: ['a',
          'href':  ($link) -> $link.attr 'href'
        ]).done handler

  cleanUrl = (base, url)  ->
    cleaned = url
    if cleaned
      # Handle //de.wikinews.org/wiki/Hauptseite
      cleaned = url.replace /\/\//g, base.scheme() + "://" if url.startsWith "//"
      # Handle relative urls with leading slash, i.e. /wiki/Hauptseite
      cleaned = URI(url).absoluteTo(base).toString() if url.startsWith "/"
      # Drop in-page anchors, i.e. #info
      cleaned = "" if url.startsWith "#"
    else
      @log "error", "URL was null"
      cleaned = ""
    cleaned

module.exports = {ResourceDiscovery}