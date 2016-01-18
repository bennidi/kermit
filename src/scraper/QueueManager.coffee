{Status} = require './CrawlRequest'
lokijs = require 'lokijs'
_ = require 'lodash'

# Provides access to a queue like system that allows to access {CrawlRequest}s by their
# status.
#
# Currently implemented on top of beautiful [http://lokijs.org lokijs]
# => Queues are emulated with dynamic views on a single request collection.
#
class QueueManager

  # Construct a new QueueManager with its own data file
  constructor: (@file) ->
    @store =  new lokijs @file
    @initialize()

  inProgress = [Status.SPOOLED, Status.FETCHING, Status.FETCHED, Status.COMPLETE]
  waiting = [Status.INITIAL, Status.SPOOLED]
  unfinished = [Status.INITIAL, Status.SPOOLED, Status.READY, Status.FETCHING, Status.FETCHED]

  # Initialize this queue manager
  initialize: () ->
    # One collection for all requests and dynamic views for various request status
    @requests = @store.addCollection 'requests'
    @visited = @store.addCollection 'visited'#, unique: ['url']
    # One view per distinct status value
    addView = (status) =>
      @requests.addDynamicView status
        .applyWhere (request) ->
          request.status is status
    addView status for status in Status.ALL

  requestsByStatus : (statuses = Status.ALL, result = {}) ->
    result[status] = @requests.getDynamicView(status).data().length for status in statuses
    result

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
  requestsWaiting: ->
    waiting = @requests.find status : $in: waiting
    waiting.length > 0

  requestsUnfinished: ->
    unfinished = @requests.find status : $in: unfinished
    unfinished.length > 0

  requestsProcessing: (pattern) ->
    ready = @requests.find $and: [
      {status : 'FETCHING'},
      {url : $regex: pattern}
    ]
    ready.length

  # Get all {CrawlRequest}s with status {RequestStatus.INITIAL}
  initial: () ->
    @requests.getDynamicView(Status.INITIAL).data()

# Retrieve the next batch of {RequestStatus.SPOOLED} requests
  # @param batchSize {Number} The maximum number of requests to be returned
  # @return {Array<CrawlRequest.state>} An arrays of requests in state SPOOLED
  spooled: (batchSize = 20) ->
    @requests.getDynamicView(Status.SPOOLED).branchResultset().simplesort('stamps.SPOOLED', true).limit(batchSize).data()


module.exports = {
  QueueManager
}
