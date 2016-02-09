{Extension} = require '../Extension'

class Histogrammer extends Extension

  constructor: () ->
    @histogram = {}
    super
      COMPLETE : (item) =>
        @histogram[item.url()] = item.pipeline().headers


  shutdown: (context) ->
    console.log JSON.stringify @histogram

module.exports = {Histogrammer}