{Phase} = require '../RequestItem'
{Extension} = require '../Extension'
_ = require 'lodash'

# Predefined filters for convenient configuration of {RequestFilter}
#
# @see http://elijahmanor.com/regular-expressions-in-coffeescript-are-awesome/ Regex in coffeescript
# @see https://coffeescript-cookbook.github.io/chapters/regular_expressions/searching-for-substrings CS Cookbook: Seaching for substrings
class Filters

  @ByPattern: (pattern) -> (url, meta) -> pattern.test url

  @MimeTypes:
    CSS : Filters.ByPattern /.*\.css/g
    JS : Filters.ByPattern /.*\.js/g
    PDF : Filters.ByPattern /.*\.pdf/g
  @AllUrls : Filters.ByPattern /.*/g

  @match : (url, meta, filters) ->
    for filter in filters
      return true if filter(url, meta)
    false

###
  Filter URLs by means of regular expressions of filter functions, i.e Function[String,Object]:Boolean.
  Supports white-listing and black-listing.

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
    # Filters can be regular expressions (evaluated on
    @opts.allow = _.map @opts.allow, (filter) -> if _.isRegExp filter then Filters.ByPattern filter else filter
    @opts.deny = _.map @opts.deny, (filter) -> if _.isRegExp filter then Filters.ByPattern filter else filter


  # Check the given URL for matching entries in blacklist/whitelist
  # @param url {String} The URL to be checked
  isAllowed: (url, meta) ->
    if (not _.isEmpty @opts.allow) and not Filters.match url, meta, @opts.allow
      @log.debug? "#{url} not on whitelist", tags:['UrlFilter']
      return false
    if Filters.match  url, meta, @opts.deny
      @log.debug? "#{url} on blacklist", tags:['UrlFilter']
      return false
    true

module.exports = {
  UrlFilter
  Filters
  ByPattern : Filters.ByPattern
  MimeTypes : Filters.MimeTypes
}