htmlToJson = require 'html-to-json'

# Wrapper around html-to-json library. Allows to compose extractors and run them against
# any piece of valid html code.
# @see https://www.npmjs.com/package/html-to-json
class HtmlExtractor

  # Create a new HtmlExtractor
  constructor: (config) ->
    @name = config.name or throw new Error "An extractor can not be unnamed"
    @selectors = config.select or throw new Error "An extractor needs selectors"
    @onResult = config.onResult or throw new Error "An extractor needs a handler to process the result"
    @parser = htmlToJson.createParser @selectors

module.exports = {
  HtmlExtractor
}