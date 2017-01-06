{Extension} = require '../Extension'
_ = require 'lodash'
{ContentType} = require('../Pipeline')
{InMemoryContentHolder} = require './core.streaming.coffee'

###

  Scan result for bad data patterns (site banned access, captcha etc)

###
class ResultVerification extends Extension
  @with InMemoryContentHolder (response) -> @options.selector response

  @defaults: ->
    bad : []
    good : []
    selector: ContentType( [/.*html.*/, /.*octet-stream/] )

  constructor: (options)->
    super options
    @on FETCHED : (item) ->
        content = item.pipeline().data()
        if _.isEmpty content then return @log.debug? "#{item.id()}", tags: ['ResultVerification', 'EMPTY']
        for handler in @options.good
          if handler item, content
            @log.debug? "#{item.id()}", tags: ['ResultVerification', 'GOOD']
            return
        for handler in @options.bad
          if handler item, content
            @log.debug? "#{item.id()}", tags: ['ResultVerification', 'BAD']
            item.error "Result verification failed"
            @qs.urls().reschedule item.url()
            @crawler.stop()

module.exports = {ResultVerification}
