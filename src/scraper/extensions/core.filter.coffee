{Status} = require '../CrawlRequest'
{Extension} = require '../Extension'
_ = require 'lodash'

# Predefined filters for convenient configuration of {RequestFilter}
#
# @see http://elijahmanor.com/regular-expressions-in-coffeescript-are-awesome/ Regex in coffeescript
# @see https://coffeescript-cookbook.github.io/chapters/regular_expressions/searching-for-substrings CS Cookbook: Seaching for substrings
class Filters

  @ByPattern: (pattern) ->
    (request) -> pattern.test request.url()

  @MimeTypes:
    CSS : Filters.ByPattern /.*\.css/g
    JS : Filters.ByPattern /.*\.js/g
    PDF : Filters.ByPattern /.*\.pdf/g
  @AllUrls : Filters.ByPattern /.*/g

  @match : (request, filters) ->
    for filter in filters
      return true if filter(request)
    false

  @matchUrl : (url, patterns) ->
    for pattern in patterns
      return true if pattern.test url
    false

class UrlFilter

  @defaultOpts : () ->
    allow : [/.*/g] # allow all by default
    deny : []

  # @nodoc
  constructor: (opts = {}) ->
    {obj} = require '../util/tools.coffee'
    @opts = obj.overlay UrlFilter.defaultOpts(), opts
    @log = @opts.log
    @log.debug? "", @opts

  # Check the given URL matching entries in blacklist/whitelist
  # @param url {String} The request to filter
  # @return {Boolean} True
  isAllowed: (url) ->
    if not Filters.matchUrl url, @opts.allow
      @log.debug? "#{url} not on whitelist", tags:['UrlFilter']
      return false
    if Filters.matchUrl  url, @opts.deny
      @log.debug? "#{url} on blacklist", tags:['UrlFilter']
      return false
    if @opts.isDuplicate url
      @log.debug? "#{url} is duplicate", tags:['UrlFilter']
      return false
    true
# Filter newly created requests based on a flexible set of filter functions.
class RequestFilter extends Extension

  @defaultOpts : () ->
    allow : [()->true] # allow all by default
    deny : []

  # @nodoc
  constructor: (opts = {} ) ->
    super INITIAL : @apply
    @opts = @merge RequestFilter.defaultOpts(), opts
    @opts.allow = _.map @opts.allow, (filter) -> if _.isRegExp filter then Filters.ByPattern filter else filter
    @opts.deny = _.map @opts.deny, (filter) -> if _.isRegExp filter then Filters.ByPattern filter else filter

  # Apply defined filters
  # Cancels the request if it is not whitelisted or blacklisted
  # @param request {CrawlRequest} The request to filter
  apply: (request) ->
    if not Filters.match(request, @opts.allow)
      @log.trace? "#{request.url()} not on whitelist", tags: ['RequestFilter']
      return request.cancel()
    if Filters.match(request, @opts.deny)
      @log.trace? "#{request.url()} on blacklist", tags: ['RequestFilter']
      return request.cancel()

module.exports = {
  UrlFilter
  RequestFilter
  Filters
  ByPattern : Filters.ByPattern
  MimeTypes : Filters.MimeTypes
}