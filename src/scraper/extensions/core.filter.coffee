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
    allowDuplicates: false
    allow : [ByUrl /.*/g] # allow all by default
    deny : []

  match = (request, filters) ->
    for filter in filters
      return true if filter(request)
    false

  constructor: (@opts = {} ) ->
    super new ExtensionDescriptor "RequestFilter", [Status.INITIAL]
    @opts = @constructor.mergeOptions RequestFilter.defaultOpts, @opts

  initialize: (context) ->
    super context
    @queue = context.queue

  apply: (request) ->
    if not match(request, @opts.allow) or match(request, @opts.deny)
      request.cancel("Request filtered")
    if @queue.contains(request.url()) and not @opts.allowDuplicates
      request.cancel("Duplicate")



module.exports = {
  RequestFilter
  ByUrl
  MimeTypes
  AllUrls
  Texts
  WithinDomain
}