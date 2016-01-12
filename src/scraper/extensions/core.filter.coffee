{Status} = require '../CrawlRequest'
{Extension} = require '../Extension'
_ = require 'lodash'

# Predefined filters for convenient configuration of {RequestFilter}
#
# @see http://elijahmanor.com/regular-expressions-in-coffeescript-are-awesome/ Regex in coffeescript
# @see https://coffeescript-cookbook.github.io/chapters/regular_expressions/searching-for-substrings CS Cookbook: Seaching for substrings
class Filters

  @ByUrl: (pattern) ->
    (request) -> request.url().match pattern

  @WithinDomain : (domain) ->
    Filters.ByUrl new RegExp(".*#{domain}\..*", "g")

  @MimeTypes:
    CSS : Filters.ByUrl /.*\.css/g
    JS : Filters.ByUrl /.*\.js/g
    PDF : Filters.ByUrl /.*\.pdf/g
  @AllUrls : Filters.ByUrl /.*/g

  @match : (request, filters) ->
    for filter in filters
      return true if filter(request)
    false

  @matchUrl : (url, patterns) ->
    for pattern in patterns
      return true if url.matches pattern
    false

class UrlFilter

  @defaultOpts : () ->
    allow : [/.*/g] # allow all by default
    deny : []

  # @nodoc
  constructor: (opts = {}) ->
    {objects} = require '../util/utils.coffee'
    @opts = objects.merge UrlFilter.defaultOpts(), opts

  # Check the given URL matching entries in blacklist/whitelist
  # @param url {String} The request to filter
  # @return {Boolean} True
  isAllowed: (url) ->
    if not Filters.matchUrl url, @opts.allow
      @log.trace? "#{url} not on whitelist", tags:['UrlFilter']
      return false
    if Filters.matchUrl  url, @opts.deny
      @log.trace? "#{url} on blacklist", tags:['UrlFilter']
      return false
    if @opts.isDuplicate url
      @log.trace? "#{url} is duplicate", tags:['UrlFilter']
      return false

# Filter newly created requests based on a flexible set of filter functions.
class RequestFilter extends Extension

  @defaultOpts : () ->
    allow : [Filters.ByUrl(/.*/g)] # allow all by default
    deny : []

  # @nodoc
  constructor: (opts = {} ) ->
    super INITIAL : @apply
    @opts = @merge RequestFilter.defaultOpts(), opts
    @opts.allow = _.map @opts.allow, (filter) -> if _.isRegExp filter then Filters.ByUrl filter else filter
    @opts.deny = _.map @opts.deny, (filter) -> if _.isRegExp filter then Filters.ByUrl filter else filter

  # Apply defined filters
  # Cancels the request if it is not whitelisted or blacklisted
  # @param request {CrawlRequest} The request to filter
  apply: (request) ->
    if not Filters.match(request, @opts.allow)
      @log.trace? "FILTERED: #{request.url()} not on whitelist"
      return request.cancel()
    if Filters.match(request, @opts.deny)
      @log.trace? "FILTERED: #{request.url()} on blacklist"
      return request.cancel()

module.exports = {
  UrlFilter
  RequestFilter
  Filters
  ByUrl : Filters.ByUrl
  WithinDomain : Filters.WithinDomain
  MimeTypes : Filters.MimeTypes
}