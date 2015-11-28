Status = require('../CrawlRequest').Status
extensions = require '../Extension'

# State transition CREATED -> SPOOLED
class RequestFilter extends extensions.Extension

  @opts =
    preventDuplicates : true
    whitelist : [] # regex for allowed requests, all pass if empty
    blacklist : [] # regex for disallowed requests, all pass if empty
    maxDepth : 2

  isBlacklisted = (url, blacklist) ->
    false

  isWhitelisted = (url, whitelist) ->
    true


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