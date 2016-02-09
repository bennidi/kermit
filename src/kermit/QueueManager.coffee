{Phase} = require './RequestItem'
lokijs = require 'lokijs'
_ = require 'lodash'

###
 Provides access to a queue like system that allows to access {RequestItem}s using lokijs query interface.
 Queues are emulated with dynamic views on a single item collection.
###
class QueueManager

  # Construct a new QueueManager with its own data file
  constructor: (@file) ->
    @store =  new lokijs @file
    @initialize()

  # List of phases considered "in-progress"
  inProgress = [Phase.SPOOLED, Phase.FETCHING, Phase.FETCHED, Phase.COMPLETE]
  # List of phases considered "waiting"
  waiting = [Phase.INITIAL, Phase.SPOOLED]
  # List of phases considered "unfinished"
  unfinished = [Phase.INITIAL, Phase.SPOOLED, Phase.READY, Phase.FETCHING, Phase.FETCHED]

  # Initialize this queue manager
  # @private
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

  # Count the number of items per phase
  # @return [Object] An object with a property for each phase associated with the
  # number of items in that phase
  itemCountByPhase : (phases = Phase.ALL, result = {}) ->
    result[phase] = @items.getDynamicView(phase).data().length for phase in phases
    result

  # Insert a item into the queue
  # @param item {RequestItem} The item to be inserted
  insert: (item) ->
    @items.insert(item.state)
    @updateUrl item.url(), 'processing', rId: item.id()

  # Update the url collection such that it reflects the current status of the given URL
  # @private
  updateUrl: (url, phase, meta) ->
    record = @urls.find url : url
    if not _.isEmpty record
      record[0].phase = phase
      record[0].meta ?= {}
      record[0].meta[key] = value for key, value of meta
      record[0].meta['tsModified'] = new Date().getTime()
      @urls.update record
    else @urls.insert {url: url, meta:meta, phase: phase}

  # Add a url as scheduled
  scheduleUrl: (url, meta) ->
    meta ?= {}
    meta.tsModified = new Date().getTime()
    @updateUrl url, 'scheduled', meta

  # Retrieve the next batch of scheduled URLs (FIFO ordered)
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

  # Whether the given url has already been visited
  isVisited: (url) -> @hasUrl url, 'visited'
  # Whether the given url is already scheduled
  isScheduled: (url) -> @hasUrl url, 'scheduled'
  # Whether the given url is currently processing
  isProcessing: (url) -> @hasUrl url, 'processing'
  # Whether the given url is known, i.e. one of [scheduled|processing|visited]
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

  # Retrieve a set of all items with phases defined as "WAITING"
  itemsWaiting: ->
    @items.getDynamicView('WAITING').data()

  # Determines whether there are items left for Spooling
  hasItemsWaiting: ->
    @itemsWaiting().length > 0

  # Determines whether there are items left for Spooling
  hasUnfinishedItems: ->
    @items.find(phase: $in: unfinished).length > 0

  # Retrieve
  itemsProcessing: (pattern) ->
    @items.find $and: [
      {phase : 'FETCHING'},
      {url : $regex: pattern}
    ]

  # Get all {RequestItem}s with phase {INITIAL}
  initial: () ->
    @items.getDynamicView(Phase.INITIAL).data()

  # Retrieve the next batch of {SPOOLED} items
  # @param batchSize {Number} The maximum number of items to be returned
  # @return {Array<RequestItem.state>} An arrays of items in state SPOOLED
  spooled: (batchSize = 20) ->
    @items.getDynamicView(Phase.SPOOLED).branchResultset().limit(batchSize).data()

  shutdown: () ->
    @store.saveDatabase()

module.exports = {
  QueueManager
}
