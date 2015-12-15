{Status} = require('../CrawlRequest')
{Extension, ExtensionDescriptor} = require '../Extension'
httpRequest = require 'request'


# Execute the request and retrieve the result for further processing.
# This extension actually issues http(s) requests and receives the resulting data.
class RequestStreamer extends Extension

  @defaultOpts =
    Tor :
      enabled : false
      port : 9050
      host: 'localhost'
    userAgent : "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"

  # Create a new Streamer
  constructor: (opts = {}) ->
    super READY:@apply
    @opts = Extension.mergeOptions RequestStreamer.defaultOpts, opts

  requestOptions = (options) ->
    requestOpts = {}
    if options.Tor.enabled
      Agent = if options.useSSL then require 'socks5-https-client/lib/Agent' else require 'socks5-http-client/lib/Agent'
      requestOpts.agentClass = Agent
      requestOpts.agentOptions =
          socksHost: options.Tor.host, # Defaults to 'localhost'.
          socksPort: options.Tor.port # Defaults to 1080.
    requestOpts

  apply: (crawlRequest) ->
    url = crawlRequest.uri().toString()
    @opts.useSSL = crawlRequest.useSSL()
    httpRequest.get url, requestOptions(@opts)
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