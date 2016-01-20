{Status} = require('../CrawlRequest')
{MemoryStream} = require('../util/tools.streams.coffee')
{obj} = require('../util/tools.coffee')
{Mimetypes} = require('../Pipeline.coffee')
{Extension} = require '../Extension'
URI = require 'urijs'
validUrl = require 'valid-url'
url = require 'url'
_ = require 'lodash'
htmlToJson = require 'html-to-json'

# Scan result data for links to other resources (css, img, js, html) and schedule
# a request to retrieve those resources.
class HtmlProcessor extends Extension

  # Create a new resource discovery extension
  constructor: (extractors) ->
    @content = {}
    @extractors = {}
    @extractors[extractor.name] = extractor for extractor in extractors
    @combinedSelectors = {}
    @combinedSelectors[name] = extractor.parser for name, extractor of @extractors
    console.log obj.print @combinedSelectors
    super
      READY : (request) =>
        target = @content[request.id()] = []
        request.channels().stream Mimetypes( [/.*htm.*/g] ), new MemoryStream target
      FETCHED : (request) =>
        input = @contents request
        handler =  (error,results) =>
          @extractors[name].onResult results[name],request for name, result of results unless error
          delete @content[request.id()] # free the memory
        if not _.isEmpty input
          try
            htmlToJson.batch input, @combinedSelectors, handler
          catch error
            @log.error? error.toString()


  contents: (request) ->
    data = @content[request.id()]
    if data.length > 1 then data.join "" else data[0]


module.exports = {HtmlProcessor}