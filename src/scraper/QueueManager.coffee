{Status} = require './CrawlRequest'
lokijs = require 'lokijs'

class QueueManager

  constructor: (@store = new lokijs 'crawlrequests.json') ->
    @initialize()

  inProgress = [Status.SPOOLED, Status.FETCHING, Status.FETCHED, Status.COMPLETE]
  waiting = [Status.INITIAL, Status.SPOOLED]

  initialize: () ->
    # One collection for all requests and dynamic views for various request status
    @requests = @store.addCollection 'requests'
    @visited = @store.addCollection 'visited', unique: ['url']
    # Fresh requests
    @requests.addDynamicView(Status.INITIAL)
             .applyWhere (request) ->
                request.status is Status.INITIAL
    # Requests that have been SPOOLED, aka ready to be processed
    @requests.addDynamicView(Status.SPOOLED)
             .applyWhere (request) ->
                request.status is Status.SPOOLED

  # Insert a request into the queue
  # @param request {CrawlRequest} The request to be inserted
  insert: (request) ->
    @requests.insert(request.state)

  # Update a known request
  # @param request {CrawlRequest} The request to be updated
  update: (request) ->
    @requests.update(request.state)

  # Check whether the given url has already been processed or
  # is on its way to being processed
  # @param request {CrawlRequest} The request to be inserted
  # @return {Boolean} True, if the url was found, false otherwise
  contains: (url) ->
    alreadyVisited = @visited.find("url":url).length
    return true if alreadyVisited > 0
    # Either in processing
    inProgress = @requests.find $and: [
      {url : url},
      {status : {$in: inProgress}}
    ]
    inProgress.length > 0

  # Handle a request that successfully completed processing
  # (run cleanup and remember the url as successfully processed).
  # @param request {CrawlRequest} The request to be inserted
  completed: (request) ->
    # remember that url has been processed successfully
    @visited.insert({url: request.url(), rId: request.id()})
    # remove request data from storage
    @requests.remove(request.state)

  # Determines whether there are requests left for Spooling
  requestsRemaining: ->
    unfinished = @requests.find status : $in: waiting
    unfinished.length > 0

  # Get all {CrawlRequest}s with status {RequestStatus.INITIAL}
  initial: () ->
    @requests.getDynamicView(Status.INITIAL).data()

  # Retrieve the next batch of {RequestStatus.SPOOLED} requests
  # @param batchSize {Number} The maximum number of requests to be returned
  # @return {Array<CrawlRequest.state>} An arrays of requests in state SPOOLED
  spooled: (batchSize = 20) ->
    @requests.getDynamicView(Status.SPOOLED).branchResultset().simplesort('tsSPOOLED', true).limit(batchSize).data()



module.exports = {
  QueueManager
}
