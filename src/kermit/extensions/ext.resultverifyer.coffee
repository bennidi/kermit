{Phase} = require '../RequestItem'
{Extension} = require '../Extension'
{HtmlProcessor} = require './ext.htmlprocessor'
URI = require 'urijs'
_ = require 'lodash'
{HtmlExtractor} = require '../Extractor'
{uri} = require '../util/tools'
{ContentType} = require('../Pipeline')
{MemoryStream} = require('../util/tools.streams')
{InMemoryContentHolder} = require './core.streaming.coffee'

###

  Scan result for bad data patterns (site banned access, captcha etc)

  @todo Expose request and response

###
class ResultVerification extends Extension
  @with InMemoryContentHolder (response) -> @opts.selector response

  @defaultOpts: ->
    bad : []
    good : []
    selector: ContentType( [/.*html.*/g, /.*octet-stream/g] )

  constructor: (@options)->
    @opts = @merge ResultVerification.defaultOpts(), @options
    super
      FETCHED : (item) =>
        content = item.pipeline().data()
        if _.isEmpty content then return @log.debug? "#{item.id()}", tags: ['ResultVerification', 'EMPTY']
        for handler in @opts.good
          if handler item, content
            @log.debug? "#{item.id()}", tags: ['ResultVerification', 'GOOD']
            return
        for handler in @opts.bad
          if handler item, content
            @log.debug? "#{item.id()}", tags: ['ResultVerification', 'BAD']
            item.cancel()
            @crawler.shutdown()

module.exports = {ResultVerification}
