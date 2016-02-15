{Phase} = require('../RequestItem')
{Extension} = require '../Extension'
httpRequest = require 'request'
https = require 'https'
http = require 'http'
socks5Https = require 'socks5-https-client/lib/Agent'
socks5Http = require 'socks5-http-client/lib/Agent'
{LogStream} = require '../util/tools'

###

  Execute the item and retrieve the result for further processing.
  This extension actually issues http(s) items and receives the resulting data.

  @see https://www.paypal-engineering.com/2014/04/01/outbound-ssl-performance-in-node-js/ Paypal Engineering on SSL performance
###
class RequestStreamer extends Extension

  # Create a new options object with the default configuration
  @defaultOpts = () ->
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
    userAgent : "Opera/9.80 (X11; Linux i686; Ubuntu/14.10) Presto/2.12.388 Version/12.16"

  # Create a new Streamer
  constructor: (opts = {}) ->
    super READY : @apply
    @opts = @merge RequestStreamer.defaultOpts(), opts
    if @opts.Tor.enabled
      agentOptions.socksHost = options.Tor.host # Defaults to 'localhost'.
      agentOptions.socksPort = options.Tor.port # Defaults to 1080.
      @opts.agents.https = new socks5Https @opts.agentOptions
      @opts.agents.http = new socks5Http @opts.agentOptions
    else
      @opts.agents.http = new http.Agent @opts.agentOptions
      @opts.agents.https = new https.Agent @opts.agentOptions

  apply: (crawlRequest) ->
    url = crawlRequest.url()
    options =
      agent: if crawlRequest.useSSL() then @opts.agents.https else @opts.agents.http
      headers :
        'User-Agent' : @opts.userAgent
    crawlRequest.fetching()
    httpRequest.get url, options
      .on 'response', (response) ->
        crawlRequest.pipeline().import response
      .on 'error', (error) =>
        @log.error? "Error while issuing of request", {msg: error.msg, trace:error.stack, tags: ['RequestStreamer']}
        crawlRequest.error()


# Export a function to create the core plugin with default extensions
module.exports = {
  RequestStreamer
}