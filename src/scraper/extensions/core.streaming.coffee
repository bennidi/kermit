{Status} = require('../CrawlRequest')
{Extension} = require '../Extension'
httpRequest = require 'request'
https = require 'https'
http = require 'http'
socks5Https = require 'socks5-https-client/lib/Agent'
socks5Http = require 'socks5-http-client/lib/Agent'
{LogStream} = require '../util/tools.coffee'


# Execute the request and retrieve the result for further processing.
# This extension actually issues http(s) requests and receives the resulting data.
# @see https://www.paypal-engineering.com/2014/04/01/outbound-ssl-performance-in-node-js/ Paypal Engineering on SSL performance
class RequestStreamer extends Extension

  @defaultOpts = () ->
    agents : {}
    Tor :
      enabled : false
      port : 9050
      host: 'localhost'
    userAgent : "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"

  # Create a new Streamer
  constructor: (opts = {}) ->
    super READY : @apply
    @opts = @merge RequestStreamer.defaultOpts(), opts
    if @opts.Tor.enabled
      agentOptions =
        socksHost: options.Tor.host, # Defaults to 'localhost'.
        socksPort: options.Tor.port # Defaults to 1080.
      @opts.agents.https = new socks5Https agentOptions
      @opts.agents.http = new socks5Http agentOptions
    else
      agentOptions =
        maxSockets: 5
        ciphers: "AES128-SHA"
      @opts.agents.http = new http.Agent agentOptions
      @opts.agents.https = new https.Agent agentOptions

  apply: (crawlRequest) ->
    url = crawlRequest.url()
    @log.debug? "Executing request #{url}"
    options =
      agent: if crawlRequest.useSSL() then @opts.agents.https else @opts.agents.http
    httpRequest.get url, options
      .on 'response', (response) ->
        crawlRequest.fetching response


# Export a function to create the core plugin with default extensions
module.exports = {
  RequestStreamer
}