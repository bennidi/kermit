{Status} = require('../CrawlRequest')
{Extension, ExtensionDescriptor} = require '../Extension'
httpRequest = require 'request'

# Execute the request and retrieve the result for further processing.
# This extension actually issues http(s) requests and receives the resulting data.
class RequestStreamer extends Extension

  @opts =
    userAgent : "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"

  constructor: () ->
    super new ExtensionDescriptor "Request Streamer", [Status.READY]

  initialize: (context) ->
    super context

  apply: (crawlRequest) ->
    url = crawlRequest.uri().toString()
    console.log "Scheduled: #{url}"
    crawlRequest.fetching()
    process.nextTick ->
      console.log "Fetching: #{url}"
      httpRequest url, (error, response, body) ->
        if not error and response.statusCode is 200
          crawlRequest.fetched(body, response)
        if error
          crawlRequest.error(error)



# Export a function to create the core plugin with default extensions
module.exports = {
  RequestStreamer
}