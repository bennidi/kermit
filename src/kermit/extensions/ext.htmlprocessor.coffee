{MemoryStream} = require('../util/tools.streams')
{ContentType} = require('../Pipeline')
_ = require 'lodash'
htmlToJson = require 'html-to-json'


class RequestDataStore

  # Attach the processor to receive response data.
  # Note: Attach to {READY}
  attach: (item) =>
    target = @content[item.id()] = []
    # Store response data in-memory for subsequent processing
    item.pipeline().stream ContentType( [/.*html.*/g] ), new MemoryStream target



# Scan result data for links to other resources (css, img, js, html) and schedule
# a item to retrieve those resources.
class HtmlProcessor

  # Create a new resource discovery extension
  constructor: (extractors) ->
    @content = {}
    @extractors = {}
    @extractors[extractor.name] = extractor for extractor in extractors
    @combinedSelectors = {}
    @combinedSelectors[name] = extractor.parser for name, extractor of @extractors

  # Attach the processor to receive response data.
  # Note: Attach to {READY}
  attach: (item) =>
    target = @content[item.id()] = []
    # Store response data in-memory for subsequent processing
    item.pipeline().stream ContentType( [/.*html.*/g] ), new MemoryStream target

  # Trigger execution of content handlers as soon as streaming has finished
  # Note: Attach to {FETCHED}
  process: (item) =>
    input = @contents item
    if not _.isEmpty input
      try
        htmlToJson.batch input, @combinedSelectors, (error,results) =>
          # Call matching (by name) result handler for each result of the extraction process
          # Note: This follows the pattern dictated by html-to-json library
          @extractors[name].onResult results[name],item for name, result of results unless error
          delete @content[item.id()] # Free the memory
      catch error
        @log.error? error.toString()

  # @private
  # @nodoc
  contents: (item) ->
    data = @content[item.id()]
    if data.length > 1 then data.join "" else data[0]


module.exports = {HtmlProcessor}