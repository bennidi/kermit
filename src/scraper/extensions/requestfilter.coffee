{Status} = require '../CrawlRequest'
extensions = require '../Extension'

# Filter requests newly created requests (state INITIAL) based on a variety of criteria.
# Requests can be filtered by
#  + their uri (whitelisting and blacklisting using regular expressions)
#  + the level of nesting (depth)
class RequestFilter extends extensions.Extension

  @opts =
    preventDuplicates : true
    whitelist : [] # regex for allowed requests, all pass if empty
    blacklist : [] # regex for disallowed requests, all pass if empty
    maxDepth : 4

  isBlacklisted = (url, blacklist) ->
    false # TODO: add real implementation

  isWhitelisted = (url, whitelist) ->
    true # TODO: add real implementation

  constructor: (@opts = RequestFilter.opts) ->
    super new extensions.ExtensionDescriptor "RequestFilter", [Status.INITIAL]

  initialize: (context) ->
    @queue = context.queue

  apply: (request) ->
    url = request.url()
    if request.depth() >= @opts.maxDepth
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