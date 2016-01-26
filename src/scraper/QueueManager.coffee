{Status} = require './CrawlRequest'
lokijs = require 'lokijs'
_ = require 'lodash'

###
 Provides access to a queue like system that allows to access {CrawlRequest}s by their
 status.

 Currently implemented on top of beautiful [http://lokijs.org lokijs]
 => Queues are emulated with dynamic views on a single request collection.
###
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
    @urls = @store.addCollection 'urls'#, unique: ['url']
    # One view per distinct status value
    addRequestView = (status) =>
      @requests.addDynamicView status
        .applyFind status: status
        .applySimpleSort "stamps.#{status}", true
    addRequestView status for status in Status.ALL
    @urls.addDynamicView 'visited'
      .applyFind status: 'visited'
      .applySimpleSort 'tsModified', true
    @urls.addDynamicView 'scheduled'
      .applyFind status: 'scheduled'
      .applySimpleSort 'tsModified', true
    @urls.addDynamicView 'processing'
      .applyFind status: 'processing'
      .applySimpleSort 'tsModified', true

  requestsByStatus : (statuses = Status.ALL, result = {}) ->
    result[status] = @requests.getDynamicView(status).data().length for status in statuses
    result

  # Insert a request into the queue
  # @param request {CrawlRequest} The request to be inserted
  insert: (request) ->
    @requests.insert(request.state)
    @updateUrl request.url(), 'processing', rId: request.id()

  updateUrl: (url, status, meta) ->
    record = @urls.getDynamicView('scheduled').branchResultset().find(url : url).data()
    if not _.isEmpty record
      record[0].status = status
      record[0].meta ?= {}
      record[0].meta[key] = value for key, value of meta
      record[0].meta['tsModified'] = new Date().getTime()
      @urls.update record

  schedule: (url, meta) ->
    meta ?= {}
    meta.tsModified = new Date().getTime()
    @urls.insert {url: url, meta:meta, status: "scheduled"}

  nextUrlBatch: (size = 100) ->
    @urls.getDynamicView('scheduled').branchResultset().limit(size).data()


  # Update a known request
  # @param request {CrawlRequest} The request to be updated
  update: (request) ->
    @requests.update(request.state)

  # Check whether the given url has already been processed or
  # is on its way to being processed
  # @param request {CrawlRequest} The request to be inserted
  # @return {Boolean} True, if the url was found, false otherwise
  hasUrl: (url, status) ->
    @urls.find({ url:url, status: status}).length > 0

  isVisited: (url) -> @hasUrl url, 'visited'
  isScheduled: (url) -> @hasUrl url, 'scheduled'
  isProcessing: (url) -> @hasUrl url, 'processing'
  isKnown: (url) ->
    @urls.find( url:url ).length > 0

  # Handle a request that successfully completed processing
  # (run cleanup and remember the url as successfully processed).
  # @param request {CrawlRequest} The request to be inserted
  completed: (request) ->
    # remember that url has been processed successfully
    @updateUrl request.url(), status:'visited'
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
    @requests.getDynamicView(Status.SPOOLED).branchResultset().limit(batchSize).data()


module.exports = {
  QueueManager
}
