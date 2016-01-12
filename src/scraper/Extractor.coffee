htmlToJson = require 'html-to-json'

# Wrapper around html-to-json library. Allows to compose extractors and run them against
# any piece of valid html code.
#
class HtmlExtractor

  # combine the selectors of all extractors
  selectors = (extractors) ->
    combined = {}
    combined[key] = value for key,value of extractor.selector for extractor in extractors
    combined

  # build function that calls all processors
  processors = (extractors) ->
    (result) ->
      extractor.processor result.filter for extractor in extractors

  # Create a new HtmlExtractor
  constructor: () ->
    @extractors = []

  extract: (selector) ->
    then : (processor) =>
      @extractors.push {selector, processor}

  process: (input) ->
    try
      htmlToJson.batch(input, htmlToJson.createParser selectors @extractors).done processors @extractors
    catch error
      console.log error

module.exports = {
  HtmlExtractor
}