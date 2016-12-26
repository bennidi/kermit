_ = require 'lodash'
htmlToJson = require 'html-to-json'


###
  Scan result data for links to other resources (css, img, js, html) and schedule a item to retrieve those resources.

  @todo Combine with Extractor. Simplify API

###
class HtmlToJson

  # Create a new resource discovery extension
  constructor: (extractors) ->
    @content = {}
    @extractors = {}
    @extractors[extractor.name] = extractor for extractor in extractors
    @combinedSelectors = {}
    @combinedSelectors[name] = extractor.parser for name, extractor of @extractors

  # Trigger execution of content handlers as soon as streaming has finished
  # Note: Attach to {FETCHED}
  process: (item) =>
    input = item.pipeline().data()
    if not _.isEmpty input
      try
        htmlToJson.batch input, @combinedSelectors, (error,results) =>
          # Call matching (by name) result handler for each result of the extraction process
          # Note: This follows the pattern dictated by html-to-json library
          @extractors[name].onResult results[name],item for name, result of results unless error
      catch error
        @log.error? error.toString()




module.exports = {HtmlToJson}
