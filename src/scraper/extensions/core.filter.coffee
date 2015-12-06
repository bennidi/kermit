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

  constructor: (@opts = {} ) ->
    super new ExtensionDescriptor "RequestFilter", [Status.INITIAL]
    @opts = @constructor.mergeOptions RequestFilter.defaultOpts, @opts

  apply: (request) ->
    if not match(request, @opts.allow)
      return request.cancel("#{request.url()} not on whitelist")
    if match(request, @opts.deny)
      return request.cancel("#{request.url()} on blacklist")


# Filter newly created (=INITIAL) requests based on a flexible set of filter functions.
class DuplicatesFilter extends Extension

  @defaultOpts =
    allowDuplicates: false

  constructor: (@opts = {} ) ->
    super new ExtensionDescriptor "DuplicatesFilter", [Status.INITIAL]
    @opts = @constructor.mergeOptions DuplicatesFilter.defaultOpts, @opts

  initialize: (context) ->
    super context
    @queue = context.queue

  apply: (request) ->
    @log "info", "Duplicate request #{request.url()}"
    if @queue.contains(request.url())
      request.cancel("Duplicate")

module.exports = {
  DuplicatesFilter
  RequestFilter
  ByUrl
  MimeTypes
  AllUrls
  Texts
  WithinDomain
}