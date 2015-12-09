{Status} = require '../CrawlRequest'
{Extension} = require '../Extension'

# Predefined filters for convenient configuration of {RequestFilter}
class Filters

  @ByUrl: (pattern) ->
    (request) ->
      request.url().match pattern

  @WithinDomain : (domain) ->
    Filters.ByUrl new RegExp(".*#{domain}\..*", "g")

  @MimeTypes:
    CSS : Filters.ByUrl /.*\.css/g
    JS : Filters.ByUrl /.*\.js/g
    PDF : Filters.ByUrl /.*\.pdf/g
  @AllUrls : Filters.ByUrl /.*/g


# Filter newly created {RequestStatus.INITIAL} requests based on a flexible set of filter functions.
class RequestFilter extends Extension

  @defaultOpts =
    allow : [Filters.ByUrl /.*/g] # allow all by default
    deny : []

  # @nodoc
  constructor: (opts = {} ) ->
    super "RequestFilter", [Status.INITIAL]
    @opts = Extension.mergeOptions RequestFilter.defaultOpts, opts


  match = (request, filters) ->
      for filter in filters
        return true if filter(request)
      false

  # Apply defined filters
  # Cancels the request if it is not whitelisted or blacklisted
  # @param request {CrawlRequest} The request to filter
  apply: (request) ->
    if not match(request, @opts.allow)
      @log.trace "FILTERED: #{request.url()} not on whitelist"
      return request.cancel()
    if match(request, @opts.deny)
      @log.trace "FILTERED: #{request.url()} on blacklist"
      return request.cancel()


# Filter out duplicate requests (requests to the same url)
class DuplicatesFilter extends Extension

  # @nodoc
  constructor: (@opts = {} ) ->
    super "DuplicatesFilter", [Status.INITIAL]

  # Initialize with {QueueManager} from context
  initialize: (context) ->
    super context
    @queue = context.queue

  # Filter out all requests with a url already fetched
  # or in progress of fetching
  apply: (request) ->
    url = request.url()
    if @queue.contains(url)
      @log.trace "FILTERED: #{url} is duplicate"
      request.cancel()

module.exports = {
  DuplicatesFilter
  RequestFilter
  Filters
  ByUrl : Filters.ByUrl
  WithinDomain : Filters.WithinDomain
  MimeTypes : Filters.MimeTypes
}