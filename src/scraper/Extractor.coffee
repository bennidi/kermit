htmlToJson = require 'html-to-json'

# An extractor is a combination of selector and processor.
# TODO: Refer to html-to-json documentation here
class Extractor

  constructor: (@selector, @processor) ->

# Wrapper around html-to-json library. Allows to compose {Extractor}s and run them against
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
    then : (handler) =>
      @extractors.push new Extractor selector, handler

  process: (input) ->
    htmlToJson.batch(input, htmlToJson.createParser selectors @extractors).done processors @extractors

module.exports = {
  HtmlExtractor
}