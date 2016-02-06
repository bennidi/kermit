{Phase} = require('../CrawlRequest')
{MemoryStream} = require('../util/tools.streams.coffee')
{obj} = require('../util/tools.coffee')
{ContentType} = require('../Pipeline.coffee')
{Extension} = require '../Extension'
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
    super
      READY : (request) =>
        target = @content[request.id()] = []
        # Store response data in-memory for subsequent processing
        request.pipeline().stream ContentType( [/.*html.*/g] ), new MemoryStream target
      FETCHED : (request) =>
        input = @contents request
        if not _.isEmpty input
          try
            htmlToJson.batch input, @combinedSelectors, (error,results) =>
              # Call matching (by name) result handler for each result of the extraction process
              # Note: This follows the pattern dictated by html-to-json library
              @extractors[name].onResult results[name],request for name, result of results unless error
              delete @content[request.id()] # Free the memory
          catch error
            @log.error? error.toString()


  # @private
  # @nodoc
  contents: (request) ->
    data = @content[request.id()]
    if data.length > 1 then data.join "" else data[0]


module.exports = {HtmlProcessor}