{Phase} = require '../RequestItem'
{Extension} = require '../Extension'
_ = require 'lodash'

# Predefined filters for convenient configuration of {RequestFilter}
#
# @see http://elijahmanor.com/regular-expressions-in-coffeescript-are-awesome/ Regex in coffeescript
# @see https://coffeescript-cookbook.github.io/chapters/regular_expressions/searching-for-substrings CS Cookbook: Seaching for substrings
class Filters

  @ByPattern: (pattern) ->
    (item) -> pattern.test item.url()

  @MimeTypes:
    CSS : Filters.ByPattern /.*\.css/g
    JS : Filters.ByPattern /.*\.js/g
    PDF : Filters.ByPattern /.*\.pdf/g
  @AllUrls : Filters.ByPattern /.*/g

  @match : (item, filters) ->
    for filter in filters
      return true if filter(item)
    false

  @matchUrl : (url, patterns) ->
    for pattern in patterns
      return true if pattern.test url
    false

###
  Filter URLs by means of regular expressions. Supports white-listing and black-listing.
###
class UrlFilter

  # Default options
  @defaultOpts : () ->
    allow : [] # allows all by default
    deny : [] # denies none by default

  # @nodoc
  constructor: (opts = {}, @log) ->
    {obj} = require '../util/tools'
    @opts = obj.overlay UrlFilter.defaultOpts(), opts
    @log.debug? "", @opts

  # Check the given URL for matching entries in blacklist/whitelist
  # @param url {String} The URL to be checked
  isAllowed: (url) ->
    if (not _.isEmpty @opts.allow) and not Filters.matchUrl url, @opts.allow
      @log.debug? "#{url} not on whitelist", tags:['UrlFilter']
      return false
    if Filters.matchUrl  url, @opts.deny
      @log.debug? "#{url} on blacklist", tags:['UrlFilter']
      return false
    true
# Filter newly created items based on a flexible set of filter functions.
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
  # Cancels the item if it is not whitelisted or blacklisted
  # @param item {RequestItem} The item to filter
  apply: (item) ->
    if not Filters.match(item, @opts.allow)
      @log.trace? "#{item.url()} not on whitelist", tags: ['RequestFilter']
      return item.cancel()
    if Filters.match(item, @opts.deny)
      @log.trace? "#{item.url()} on blacklist", tags: ['RequestFilter']
      return item.cancel()

module.exports = {
  UrlFilter
  RequestFilter
  Filters
  ByPattern : Filters.ByPattern
  MimeTypes : Filters.MimeTypes
}