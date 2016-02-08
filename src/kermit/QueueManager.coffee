{Phase} = require './RequestItem'
lokijs = require 'lokijs'
_ = require 'lodash'

###
 Provides access to a queue like system that allows to access {RequestItem}s by their
 phase.

 Currently implemented on top of beautiful [http://lokijs.org lokijs]
 => Queues are emulated with dynamic views on a single item collection.
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
    # One collection for all items and dynamic views for various item phase
    @items = @store.addCollection 'items'
    @urls = @store.addCollection 'urls', unique: ['url']
    # One view per distinct phase value
    addRequestView = (phase) =>
      @items.addDynamicView phase
        .applyFind phase: phase
        .applySimpleSort "stamps.#{phase}", true
    addRequestView phase for phase in Phase.ALL
    @items_waiting = @items.addDynamicView 'WAITING'
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

  itemsByPhase : (phases = Phase.ALL, result = {}) ->
    result[phase] = @items.getDynamicView(phase).data().length for phase in phases
    result

  # Insert a item into the queue
  # @param item {RequestItem} The item to be inserted
  insert: (item) ->
    @items.insert(item.state)
    @updateUrl item.url(), 'processing', rId: item.id()

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


  # Update a known item
  # @param item {RequestItem} The item to be updated
  update: (item) ->
    @items.update(item.state)

  # Check whether the given url has already been processed or
  # is on its way to being processed
  # @param item {RequestItem} The item to be inserted
  # @return {Boolean} True, if the url was found, false otherwise
  hasUrl: (url, phase) ->
    @urls.find({ url:url, phase: phase}).length > 0

  isVisited: (url) -> @hasUrl url, 'visited'
  isScheduled: (url) -> @hasUrl url, 'scheduled'
  isProcessing: (url) -> @hasUrl url, 'processing'
  isKnown: (url) ->
    @urls.find( url:url ).length > 0

  # Handle a item that successfully completed processing
  # (run cleanup and remember the url as successfully processed).
  # @param item {RequestItem} The item to be inserted
  completed: (item) ->
    # remember that url has been processed successfully
    @updateUrl item.url(), 'visited'
    # remove item data from storage
    @items.remove(item.state)

  itemsWaiting: ->
    @items.getDynamicView('WAITING').data()

  # Determines whether there are items left for Spooling
  hasRequestsWaiting: ->
    waiting = @items.find phase : $in: waiting
    waiting.length > 0

  hasRequestsUnfinished: ->
    unfinished = @items.find phase : $in: unfinished
    unfinished.length > 0

  itemsProcessing: (pattern) ->
    ready = @items.find $and: [
      {phase : 'FETCHING'},
      {url : $regex: pattern}
    ]
    ready.length

  # Get all {RequestItem}s with phase {INITIAL}
  initial: () ->
    @items.getDynamicView(Phase.INITIAL).data()

  # Retrieve the next batch of {SPOOLED} items
  # @param batchSize {Number} The maximum number of items to be returned
  # @return {Array<RequestItem.state>} An arrays of items in state SPOOLED
  spooled: (batchSize = 20) ->
    @items.getDynamicView(Phase.SPOOLED).branchResultset().limit(batchSize).data()


module.exports = {
  QueueManager
}
