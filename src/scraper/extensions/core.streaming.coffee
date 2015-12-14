{Status} = require('../CrawlRequest')
{Extension, ExtensionDescriptor} = require '../Extension'
httpRequest = require 'request'

# Execute the request and retrieve the result for further processing.
# This extension actually issues http(s) requests and receives the resulting data.
class RequestStreamer extends Extension

  @defaultOpts =
    userAgent : "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"

  # Create a new Streamer
  constructor: (opts = {}) ->
    super READY:@apply
    @opts = Extension.mergeOptions RequestStreamer.defaultOpts, opts

  apply: (crawlRequest) ->
    url = crawlRequest.uri().toString()
    httpRequest.get url
      .on 'response', (response) ->
        crawlRequest.fetching()
        response.pipe crawlRequest.response.incoming
        # TODO: copy useful response attributes
      .on 'error', (error) ->
        crawlRequest.error(error)
      .on 'end', ->
        crawlRequest.fetched()
      .pipe(crawlRequest.response.incoming)

# Export a function to create the core plugin with default extensions
module.exports = {
  RequestStreamer
}