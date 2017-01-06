{Extension} = require '../Extension'
httpRequest = require 'request'
https = require 'https'
http = require 'http'
socks5Https = require 'socks5-https-client/lib/Agent'
socks5Http = require 'socks5-http-client/lib/Agent'
mime = require 'mime'

###

  Execute the item and retrieve the result for further processing.
  This extension actually issues http(s) items and receives the resulting data.

  @see https://www.paypal-engineering.com/2014/04/01/outbound-ssl-performance-in-node-js/ Paypal Engineering on SSL performance
###
class RequestStreamer extends Extension

  # Create a new options object with the default configuration
  @defaults : ->
    debug: off
    agents : {}
    agentOptions:
      maxSockets: 15
      keepAlive: true
      maxFreeSockets: 150
      keepAliveMsecs: 3000
      ciphers: "AES256-GCM-SHA384" # Disallow expensive Diffie-Hellman, see blog post of paypal engineering
    Tor :
      enabled : false
      port : 9050
      host: 'localhost'

  # Create a new Streamer
  constructor: (options = {}) ->
    super options
    @on READY : @apply
    if @options.debug then require('request-debug')(httpRequest)
    if @options.Tor.enabled
      @options.agentOptions.socksHost = @options.Tor.host # Defaults to 'localhost'.
      @options.agentOptions.socksPort = @options.Tor.port # Defaults to 1080.
      @options.agents.https = new socks5Https @options.agentOptions
      @options.agents.http = new socks5Http @options.agentOptions
    else
      @options.agents.http = new http.Agent @options.agentOptions
      @options.agents.https = new https.Agent @options.agentOptions

  apply: (item) ->
    url = item.url()
    userAgent = item.get 'user-agent'
    options =
      agent: if item.useSSL() then @options.agents.https else @options.agents.http
      headers : userAgent.headers()
    options.headers['Referer'] = item.get 'Referer'
    userAgent.addCookies options.headers, item.url()
    item.fetching()
    httpRequest.get url, options
      .on 'response', (response) ->
        # Try sanitize missing content-type
        if not response.headers['content-type'] then response.headers['content-type'] = mime.lookup url
        item.pipeline().import response
        userAgent.import response, item.url()
      .on 'error', (error) =>
        @log.error? "Error while issuing of request", {msg: error.msg, trace:error.stack, tags: ['RequestStreamer']}
        item.error()

{MemoryStream} = require('../util/tools.streams')

InMemoryContentHolder = (guard)->

  class extends Extension

    constructor:->
      super()
        # Attach the processor to receive response data.
      @on READY: (item) =>
          # Store response data in-memory for subsequent processing
          item.pipeline().stream guard.bind(@), new MemoryStream item.pipeline().target()




# Export a function to create the core plugin with default extensions
module.exports = {
  RequestStreamer
  InMemoryContentHolder
}
