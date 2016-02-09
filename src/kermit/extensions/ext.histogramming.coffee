{Extension} = require '../Extension'

class Histogrammer extends Extension

  constructor: () ->
    @histogram = {}
    @urlCount = 0
    # collect url, title, keywords, number of links, content-length
    super
      COMPLETE : (item) =>
        @histogram[item.url()] = item.pipeline().headers
        @urlCount++


  shutdown: (context) ->
    @log.info? JSON.stringify @histogram
    @log.info? "Found #{@urlCount} URLs"

module.exports = {Histogrammer}