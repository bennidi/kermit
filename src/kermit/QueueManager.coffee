{Phase} = require './RequestItem'
lokijs = require 'lokijs'
_ = require 'lodash'

###
 Provides access to a queue like system that allows to access {RequestItem}s and URLs.
###
class QueueManager

  # List of phases considered "in-progress"
  inProgress = [Phase.SPOOLED, Phase.FETCHING, Phase.FETCHED, Phase.COMPLETE]
  # List of phases considered "waiting"
  waiting = [Phase.INITIAL, Phase.SPOOLED]
  # List of phases considered "unfinished"
  unfinished = [Phase.INITIAL, Phase.SPOOLED, Phase.READY, Phase.FETCHING, Phase.FETCHED]

  # Construct a new QueueManager with its own data file
  constructor: (@file, @log) ->
    @store =  new lokijs @file
    # One collection for all items and dynamic views for various item phase
    @items = @store.addCollection 'items'
    @urls = new UrlManager @log
    # One view per distinct phase value
    addRequestView = (phase) =>
      @items.addDynamicView phase
      .applyFind phase: phase
      .applySimpleSort "stamps.#{phase}", true
    addRequestView phase for phase in Phase.ALL
    @items_waiting = @items.addDynamicView 'WAITING'
      .applyFind phase: $in : waiting


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
    @urls.processing item.url(), rId: item.id()

  # Update a known item
  # @param item {RequestItem} The item to be updated
  update: (item) ->
    @items.update(item.state)

  # Handle a item that successfully completed processing
  # (run cleanup and remember the url as successfully processed).
  # @param item {RequestItem} The item to be inserted
  completed: (item) ->
    # remember that url has been processed successfully
    @urls.visited item.url()
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

  # @private
  # Save the current state to file
  shutdown: () ->
    @store.saveDatabase()


###
  Manage the collection of URLs that are
    scheduled => to be processed in the future
    processing => being processed in form of a {RequestItem}
    visited => completed processing (RequestItem reached phase COMPLETE)
###
class UrlManager

  Datastore = require 'nedb' # Use nedb as backend
  sync = require 'synchronize'

  # Create a new URL manager
  constructor:(@log) ->
    @urls = new Datastore
    @urls.ensureIndex {fieldName: 'url', unique:true}, (err) ->
    @counter = # Maintain counters for URLs per phase to reduce load on db
      scheduled : 0
      visited : 0

  # Transition the given URL from 'scheduled' to 'processing'.
  # Inserts a new entry if no scheduled URL has been found.
  processing: (url, phase, meta) ->
    @urls.update { url:  url, phase: 'scheduled'}, { $set: {phase : phase, meta:meta}},{}, (err, updates) =>
      if updates is 0 # Not found -> wasn't previously scheduled but executed directly
        @urls.insert {url:url, phase:phase, meta:meta}, ()->
      else
        @counter.scheduled--

  # Returns the number of URLs in given phase
  count: (phase) ->
    @counter[phase]

  # Add the given URL to the collection of scheduled URLs
  schedule: (url, meta) ->
    # Insertion of duplicate URL will result in unique constraint violation
    @urls.insert {url:url, phase:'scheduled', meta:meta}, (err, result) =>
      if not err
        @log.debug? "Scheduled #{url}"
        @counter.scheduled++

  # Mark a known URL as visited (silently ignores cases of unknown URLs)
  visited: (url) ->
    @urls.update { url:  url}, { $set: {phase : 'visited'}},{}, (err, updates) => @counter.visited++ unless err

  # Execute callback if URL is not known
  ifUnknown: (url, callback) ->
    @urls.findOne url:url, (err, doc) ->
      callback() unless doc

  # Retrieve the next batch of scheduled URLs (FIFO ordered)
  scheduled: (size = 100, callback) ->
    @urls.find(phase:'scheduled').limit(size).exec (err, urls) ->
      callback urls unless err


module.exports = {
  QueueManager
}
