{Status} = require '../CrawlRequest'
{Extension, ExtensionDescriptor} = require '../Extension'


ByUrl = (pattern) ->
  (request) ->
    request.url().match pattern

WithinDomain = (domain) ->
  ByUrl new RegExp(".*#{domain}\..*", "g")

MimeTypes =
  CSS : ByUrl /.*\.css/g
  JS : ByUrl /.*\.js/g
  PDF : ByUrl /.*\.pdf/g
AllUrls = ByUrl /.*/g
Texts = {}

# Filter newly created (=INITIAL) requests based on a flexible set of filter functions.
class RequestFilter extends Extension

  @defaultOpts =
    allow : [ByUrl /.*/g] # allow all by default
    deny : []

  match = (request, filters) ->
    for filter in filters
      return true if filter(request)
    false

  constructor: (opts = {} ) ->
    super new ExtensionDescriptor "RequestFilter", [Status.INITIAL]
    @opts = Extension.mergeOptions RequestFilter.defaultOpts, opts

  apply: (request) ->
    if not match(request, @opts.allow)
      @log.trace "FILTERED: #{request.url()} not on whitelist"
      return request.cancel()
    if match(request, @opts.deny)
      @log.trace "FILTERED: #{request.url()} on blacklist"
      return request.cancel()


# Filter newly created (=INITIAL) requests based on a flexible set of filter functions.
class DuplicatesFilter extends Extension

  @defaultOpts =
    allowDuplicates: false

  constructor: (opts = {} ) ->
    super new ExtensionDescriptor "DuplicatesFilter", [Status.INITIAL]
    @opts = Extension.mergeOptions DuplicatesFilter.defaultOpts, opts

  initialize: (context) ->
    super context
    @queue = context.queue

  apply: (request) ->
    url = request.url()
    if @queue.contains(url)
      @log.trace "FILTERED: #{url} is duplicate"
      request.cancel()

module.exports = {
  DuplicatesFilter
  RequestFilter
  ByUrl
  MimeTypes
  AllUrls
  Texts
  WithinDomain
}