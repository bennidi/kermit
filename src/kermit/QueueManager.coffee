{obj, Synchronizer} = require './util/tools'
{Phase} = require './RequestItem.Phases'
lokijs = require 'lokijs'
_ = require 'lodash'
Datastore = require 'nedb' # Use nedb as backend
sync = require 'synchronize'

class QueueSystem

  @defaultOptions: () ->
    filename: "/tmp/#{obj.randomId()}"

  constructor: (options = {}) ->
    @options = obj.merge QueueSystem.defaultOptions(), options
    @_ = {}
    @_.items = new RequestItemStore @options.filename + "items.json", @options.log
    @_.urls = new UrlStore @options.log

  # Handle a item that successfully completed processing
  # (run cleanup and remember the url as successfully processed).
  # @param item {RequestItem} The item to be inserted
  completed: (item) ->
  # remember that url has been processed successfully
    @_.urls.visited item.url()
    # remove item data from storage
    @_.items.remove(item.state)

  initial: (item) ->
    @_.items.insert item
    @_.urls.processing item.url()

  items: () ->
    @_.items

  urls: () ->
    @_.urls

  shutdown: () ->
    @_.urls.shutdown?()
    @_.items.shutdown?()

###
 Provides access to a queue like system that allows to access {RequestItem}s and URLs.
###
class RequestItemStore

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
    # One view per distinct phase value
    addRequestView = (phase) =>
      @items.addDynamicView phase
      .applyFind phase: phase
      .applySimpleSort "stamps.#{phase}", true
    addRequestView phase for phase in Phase.ALL
    @items_waiting = @items.addDynamicView 'WAITING'
      .applyFind phase: $in : waiting

  # Insert a item into the queue
  # @param item {RequestItem} The item to be inserted
  insert: (item) -> @items.insert item.state

  # Update a known item
  # @param item {RequestItem} The item to be updated
  update: (item) -> @items.update item.state

  # Remove an item from the store
  remove: (item) -> @items.remove item

  # Retrieve a set of all items with phases defined as "WAITING"
  waiting: -> @items.getDynamicView('WAITING').data()

  # Retrieve a set of all items with phases defined as "WAITING"
  fetching: -> @items.getDynamicView(Phase.FETCHING).data()

  # Determines whether there are items left for Spooling
  hasWaiting: -> @itemsWaiting().length > 0

  # Determines whether there are items left for Spooling
  hasUnfinished: -> @items.find(phase: $in: unfinished).length > 0

  inPhases : (phases)  -> @items.find(phase: $in: phases)

  # Retrieve
  processing: (pattern) ->
    @items.find $and: [
      {phase : 'FETCHING'},
      {url : $regex: pattern}
    ]

  # Get all {RequestItem}s with phase {INITIAL}
  initial: () -> @items.getDynamicView(Phase.INITIAL).data()

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
class UrlStore
  @include Synchronizer

  # Create a new URL manager
  constructor:(@log) ->
    @urls = new Datastore autoload:true
    @urls.ensureIndex {fieldName: 'url', unique:true}, (err) ->
    #sync @urls, 'find'
    @counter = # Maintain counters for URLs per phase to reduce load on db
      scheduled : 0
      visited : 0

  # Transition the given URL from 'scheduled' to 'processing'.
  # Inserts a new entry if no scheduled URL has been found.
  processing: (url, phase, meta) ->
    update = phase : 'processing'
    update['meta'] = meta if meta
    @urls.update { url:  url, phase: 'scheduled'}, { $set: update},{}, (err, updates) =>
      if updates is 0 # Not found -> wasn't previously scheduled but executed directly
        record =
          url:url
          phase:'processing'
        record['meta'] = meta if meta
        @urls.insert record, ()->
      else
        @counter.scheduled--

  # Returns the number of URLs in given phase
  count: (phase) ->
    @counter[phase]

  # Add the given URL to the collection of scheduled URLs
  schedule: (url, meta) ->
    record =
      url:url
      phase:'scheduled'
    record['meta'] = meta if meta
    @urls.insert record, (err, result) =>
      if not err
        @log.debug? "Scheduled #{url}"
        @counter.scheduled++

  # Mark a known URL as visited (silently ignores cases of unknown URLs)
  visited: (url) ->
    @urls.update { url:  url}, { $set: {phase : 'visited'}},{}, (err, updates) => @counter.visited++ unless err

  # Retrieve the next batch of scheduled URLs (FIFO ordered)
  scheduled: (size = 100) ->
    @await @urls.find(phase:'scheduled').limit(size).exec @defer()


module.exports = {
  QueueSystem
}
