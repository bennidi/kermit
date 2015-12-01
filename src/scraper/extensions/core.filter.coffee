{Status} = require '../CrawlRequest'
{Extension, ExtensionDescriptor} = require '../Extension'

# Filter requests newly created requests (state INITIAL) based on a variety of criteria.
# Requests can be filtered by
#  + their uri (whitelisting and blacklisting using regular expressions)
#  + the level of nesting (depth)
class RequestFilter extends Extension

  @defaultOpts =
    preventDuplicates : true
    whitelist : [/.*/g] # regex for allowed requests, none pass if empty
    blacklist : [] # regex for disallowed requests, all pass if empty
    maxDepth : 0 # no follow up requests allowed by default

  isBlacklisted = (url, blacklist) ->
    blacklist.length > 0 and matches url, blacklist

  isWhitelisted = (url, whitelist) ->
    whitelist.length > 0 and matches url, whitelist

  matches = (url, patterns) ->
    true # TODO: add real implementation

  constructor: (@opts = {} ) ->
    super new ExtensionDescriptor "RequestFilter", [Status.INITIAL]
    @opts = @constructor.mergeOptions RequestFilter.defaultOpts, @opts

  initialize: (context) ->
    super context
    @queue = context.queue

  apply: (request) ->
    url = request.url()
    if request.depth() > @opts.maxDepth
      request.cancel("Maximum depth reached")
    if not @isWhitelisted(url)
      request.cancel("Not on whitelist")
    if @isBlacklisted(url)
      request.cancel("Blacklisted")
    if @queue.contains(url)
      request.cancel("Duplicate")

  isBlacklisted : (url) ->
    isBlacklisted(url, @opts.blacklist)

  isWhitelisted : (url) ->
    isWhitelisted(url, @opts.whitelist)

module.exports = RequestFilter