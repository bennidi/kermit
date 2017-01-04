{Extension} = require '../Extension'
_ = require 'lodash'
{ContentType} = require('../Pipeline')
{InMemoryContentHolder} = require './core.streaming.coffee'

###

  Scan result for bad data patterns (site banned access, captcha etc)

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
            item.error "Result verification failed"
            @qs.urls().reschedule item.url()
            @crawler.stop()

module.exports = {ResultVerification}
