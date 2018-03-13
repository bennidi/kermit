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
        for isGood in @options.good
          if isGood item, content
            @log.debug? "#{item.id()}", tags: ['ResultVerification', 'GOOD']
            return
        for isBad in @options.bad
          if isBad item, content
            @context.notify "Result verification failed"
            @log.debug? "#{item.id()}", tags: ['ResultVerification', 'BAD']
            item.error "Result verification failed"
            @qs.urls().reschedule item.url()
            @crawler.stop()
            @options.onFail?.call @



module.exports = {ResultVerification}
