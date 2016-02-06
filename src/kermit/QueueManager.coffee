{Phase} = require './CrawlRequest'
lokijs = require 'lokijs'
_ = require 'lodash'

###
 Provides access to a queue like system that allows to access {CrawlRequest}s by their
 phase.

 Currently implemented on top of beautiful [http://lokijs.org lokijs]
 => Queues are emulated with dynamic views on a single request collection.
###
class QueueManager

  # Construct a new QueueManager with its own data file
  constructor: (@file) ->
    @store =  new lokijs @file
    @initialize()

  inProgress = [Phase.SPOOLED, Phase.FETCHING, Phase.FETCHED, Phase.COMPLETE]
  waiting = [Phase.INITIAL, Phase.SPOOLED]
  unfinished = [Phase.INITIAL, Phase.SPOOLED, Phase.READY, Phase.FETCHING, Phase.FETCHED]

  # Initialize this queue manager
  initialize: () ->
    # One collection for all requests and dynamic views for various request phase
    @requests = @store.addCollection 'requests'
    @urls = @store.addCollection 'urls', unique: ['url']
    # One view per distinct phase value
    addRequestView = (phase) =>
      @requests.addDynamicView phase
        .applyFind phase: phase
        .applySimpleSort "stamps.#{phase}", true
    addRequestView phase for phase in Phase.ALL
    @requests_waiting = @requests.addDynamicView 'WAITING'
      .applyFind phase: $in : waiting
    @urls.addDynamicView 'visited'
      .applyFind phase: 'visited'
      .applySimpleSort 'tsModified', true
    @urls.addDynamicView 'scheduled'
      .applyFind phase: 'scheduled'
      .applySimpleSort 'tsModified', true
    @urls.addDynamicView 'processing'
      .applyFind phase: 'processing'
      .applySimpleSort 'tsModified', true

  requestsByPhase : (phases = Phase.ALL, result = {}) ->
    result[phase] = @requests.getDynamicView(phase).data().length for phase in phases
    result

  # Insert a request into the queue
  # @param request {CrawlRequest} The request to be inserted
  insert: (request) ->
    @requests.insert(request.state)
    @updateUrl request.url(), 'processing', rId: request.id()

  updateUrl: (url, phase, meta) ->
    record = @urls.find(url : url)
    if not _.isEmpty record
      record[0].phase = phase
      record[0].meta ?= {}
      record[0].meta[key] = value for key, value of meta
      record[0].meta['tsModified'] = new Date().getTime()
      @urls.update record
    else @urls.insert {url: url, meta:meta, phase: phase}

  schedule: (url, meta) ->
    meta ?= {}
    meta.tsModified = new Date().getTime()
    @updateUrl url, 'scheduled', meta

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
  hasUrl: (url, phase) ->
    @urls.find({ url:url, phase: phase}).length > 0

  isVisited: (url) -> @hasUrl url, 'visited'
  isScheduled: (url) -> @hasUrl url, 'scheduled'
  isProcessing: (url) -> @hasUrl url, 'processing'
  isKnown: (url) ->
    known = @urls.find( url:url ).length > 0
    console.log "Checking for existence of url #{url}: #{known}"
    known

  # Handle a request that successfully completed processing
  # (run cleanup and remember the url as successfully processed).
  # @param request {CrawlRequest} The request to be inserted
  completed: (request) ->
    # remember that url has been processed successfully
    @updateUrl request.url(), 'visited'
    # remove request data from storage
    @requests.remove(request.state)

  requestsWaiting: ->
    @requests.getDynamicView('WAITING').data()

  # Determines whether there are requests left for Spooling
  hasRequestsWaiting: ->
    waiting = @requests.find phase : $in: waiting
    waiting.length > 0

  hasRequestsUnfinished: ->
    unfinished = @requests.find phase : $in: unfinished
    unfinished.length > 0

  requestsProcessing: (pattern) ->
    ready = @requests.find $and: [
      {phase : 'FETCHING'},
      {url : $regex: pattern}
    ]
    ready.length

  # Get all {CrawlRequest}s with phase {INITIAL}
  initial: () ->
    @requests.getDynamicView(Phase.INITIAL).data()

  # Retrieve the next batch of {SPOOLED} requests
  # @param batchSize {Number} The maximum number of requests to be returned
  # @return {Array<CrawlRequest.state>} An arrays of requests in state SPOOLED
  spooled: (batchSize = 20) ->
    @requests.getDynamicView(Phase.SPOOLED).branchResultset().limit(batchSize).data()


module.exports = {
  QueueManager
}
