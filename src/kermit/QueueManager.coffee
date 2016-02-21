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
    @_.items = new RequestItemStore @options.filename + ".items.db", @options.log
    @_.urls = new UrlStore @options.filename + ".urls.db", @options.log

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

  save: () ->
    @_.urls.save?()
    @_.items.save?()

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
    # Maintain dynamic views for most frequent queries
    @items_waiting = @items.addDynamicView 'WAITING'
      .applyFind phase: $in : waiting
    @items_spooled = @items.addDynamicView 'SPOOLED'
      .applyFind phase: Phase.SPOOLED
    @items_fetching = @items.addDynamicView 'FETCHING', persistent: true
      .applyFind phase: Phase.FETCHING

  # Insert a item into the queue
  # @param item {RequestItem} The item to be inserted
  insert: (item) -> @items.insert item.state

  # Update a known item
  # @param item {RequestItem} The item to be updated
  update: (item) -> @items.update item.state

  # Remove an item from the store
  remove: (item) -> @items.remove item

  # Retrieve the next batch of {SPOOLED} items
  # @param batchSize {Number} The maximum number of items to be returned
  # @return {Array<RequestItem.state>} An arrays of items in state SPOOLED
  spooled: () -> @items_spooled.data()

  # Retrieve a set of all items with phases defined as "WAITING"
  waiting: -> @items_waiting.data()

  # Retrieve a set of all items with phases defined as "WAITING"
  fetching: -> @items.find phase: Phase.FETCHING

  # Determines whether there are items left for Spooling
  unfinished: -> @items.find(phase: $in: unfinished)

  inPhases : (phases)  -> @items.find(phase: $in: phases)

  # Retrieve
  processing: (pattern) ->
    @items_fetching.branchResultset()
      .find(url : $regex: pattern).data() # possible tuning: make "domain" a field and match per domain without regex

  # @private
  # Save the current state to file
  save: () ->
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
  constructor:(@file, @log) ->
    @urls = new Datastore {autoload:true, filename:@file}
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

  save: ->
    @urls.persistence.compactDatafile()

module.exports = {
  QueueSystem
}
