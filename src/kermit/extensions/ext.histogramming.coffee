{Extension} = require '../Extension'

class Histogrammer extends Extension

  constructor: () ->
    @histogram = {}
    @urlCount = 0
    super
      COMPLETE : (item) =>
        @histogram[item.url()] = item.pipeline().headers
        @urlCount++


  shutdown: (context) ->
    @log.info? JSON.stringify @histogram
    @log.info? "Found #{@urlCount} URLs"

module.exports = {Histogrammer}