{Status} = require '../CrawlRequest'
{Extension} = require '../Extension'

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


# Filter newly created requests based on a flexible set of filter functions.
class RequestFilter extends Extension

  @defaultOpts : () ->
    allow : [Filters.ByUrl(/.*/g)] # allow all by default
    deny : []

  # @nodoc
  constructor: (opts = {} ) ->
    super INITIAL : @apply
    @opts = @merge RequestFilter.defaultOpts(), opts

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


# Filter out duplicate requests (requests to the same url)
class DuplicatesFilter extends Extension

  # @nodoc
  constructor: (@opts = {} ) ->
    super INITIAL : @apply

  # Initialize with {QueueManager} from context
  initialize: (context) ->
    super context
    @queue = context.queue

  # Filter out all requests with a url already fetched
  # or in progress of fetching
  apply: (request) ->
    url = request.url()
    if @queue.contains(url)
      @log.trace? "FILTERED: #{url} is duplicate"
      request.cancel()

module.exports = {
  DuplicatesFilter
  RequestFilter
  Filters
  ByUrl : Filters.ByUrl
  WithinDomain : Filters.WithinDomain
  MimeTypes : Filters.MimeTypes
}