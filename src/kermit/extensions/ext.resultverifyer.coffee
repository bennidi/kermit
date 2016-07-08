{Phase} = require '../RequestItem'
{Extension} = require '../Extension'
{HtmlProcessor} = require './ext.htmlprocessor'
URI = require 'urijs'
_ = require 'lodash'
{HtmlExtractor} = require '../Extractor'
{uri} = require '../util/tools'
{ContentType} = require('../Pipeline')
{MemoryStream} = require('../util/tools.streams')

###
 Scan result for bad data patterns (site banned access, captcha etc)
###
class ResultVerification extends Extension

  @defaultOpts: ->
    bad : []
    good : []

  constructor: (@options)->
    @opts = @merge ResultVerification.defaultOpts(), @options
    @content = {}
    super
      READY: (item) =>
        target = @content[item.id()] = []
        # Store response data in-memory for subsequent processing
        item.pipeline().stream ContentType( [/.*html.*/g] ), new MemoryStream target
      FETCHED : (item) =>
        data = @content[item.id()]
        content = if data.length > 1 then data.join "" else data[0]
        return if not content
        for handler in @opts.good
          if handler item, content
            @log.debug? "Good content for item #{item.id()}", tags: ['ResultVerification', 'GOOD']
            return
        for handler in @opts.bad
          if handler item, content
            @log.debug? "Bad content detected for item #{item.id()}", tags: ['ResultVerification', 'BAD']
            item.cancel()
            @crawler.shutdown()
      COMPLETE: (item) => delete @content[item.id()]

module.exports = {ResultVerification}