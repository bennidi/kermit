{Phase} = require '../RequestItem'
{Extension} = require '../Extension'
{HtmlProcessor} = require './ext.htmlprocessor'
URI = require 'urijs'
_ = require 'lodash'
{HtmlExtractor} = require '../Extractor'
{uri} = require '../util/tools'


# Scan result data for bad data patterns (site banned access, captcha etc)
class ResultVerification extends Extension

  @defaultOpts: ->
    checks : {}

  # Create a new resource discovery extension
  constructor: (@options)->
    @opts = @merge ResultVerification.defaultOpts(), @options
    checks = {}
    for check in [0...@options.checks.length]
      checks['check-'+check] = @options.checks[check]
    @processor = new HtmlProcessor [
      new HtmlExtractor
        name : 'all'
        select : checks
        onResult : (results, item) =>
          for index of checks
            if _.isEmpty _.collect(results['check-'+index], _.isTrue)
              @log.debug? "Result of #{item.url()} BAD"
              item.cancel()
              @qs.urls().reschedule item.url()
              @crawler.stop()
            else
              @log.debug? "Result of #{item.url()} OK"
    ]
    super
      READY: @processor.attach
      FETCHED: @processor.process


module.exports = {ResultVerification}