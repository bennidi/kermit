{obj, files, Synchronizer} = require './util/tools'
{Phase} = require './RequestItem.Phases'
lokijs = require 'lokijs'
_ = require 'lodash'
Datastore = require 'nedb'
{Mixin} = require 'coffee-latte'

class QueueSystem

  @defaultOptions: ->
    filename: "/tmp/#{obj.randomId()}"

  constructor: (options = {}) ->
    @options = obj.merge QueueSystem.defaultOptions(), options
    @log = options.log

  initialize: (done) ->
    itemsReady = false
    urlsReady = false
    ready = =>
      @log.debug? "Queue System fully initialized", tags: ['QSys']
      @options.onReady?()
      done?()
    @options.urlsReady = =>
      @log.debug? "Url database loaded", tags: ['QSys']
      urlsReady = true
      ready() if itemsReady
    @options.itemsReady = =>
      @log.debug? "Items database loaded", tags: ['QSys']
      itemsReady = true
      ready() if urlsReady
    @_items = new RequestItemStore @options
    @_urls = new UrlStore @options
    @

  # Handle a item that successfully completed processing
  # (run cleanup and remember the url as successfully processed).
  # @param item {RequestItem} The item to be inserted
  completed: (item) ->
    # remember that url has been processed successfully
    @_urls.visited item.url()
    # remove item data from storage
    @_items.remove(item.state)

  initial: (item) ->
    @_items.insert item
    @_urls.processing item.url()

  # Add the given URL to the collection of scheduled URLs
  schedule: (url, meta) ->  @_urls.schedule url, meta

  items: -> @_items

  urls: -> @_urls

  save: ->
    @_urls.save()
    @_items.save()
    @log.info? "Queue System saved to files #{@options.filename}.[items|urls].db"

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


  # Construct a new QueueSystem with its own data file
  constructor: (@options) ->
    filename = @options.filename + '.items.db'
    isNewDB = not files.exists filename
    @store =  new lokijs filename, autosave: false
    @log = @options.log
    if isNewDB
      @log.debug? "Creating new database for request items", tags: ['QSys']
      # One collection for all items and dynamic views for various item phase
      @items = @store.addCollection 'items'
      # Maintain dynamic views for most frequent queries
      @items_waiting = @items.addDynamicView 'WAITING'
        .applyFind phase: $in : waiting
      @items_spooled = @items.addDynamicView 'SPOOLED'
        .applyFind phase: Phase.SPOOLED
      @items_fetching = @items.addDynamicView 'FETCHING', persistent: true
        .applyFind phase: Phase.FETCHING
      @options.itemsReady()
    else
      @log.debug? "Initializing existing database #{filename}", tags: ['QSys']
      @store.loadDatabase {}, =>
        @items = @store.getCollection 'items'
        @items_waiting = @items.getDynamicView 'WAITING'
        @items_spooled = @items.getDynamicView 'SPOOLED'
        @items_fetching = @items.getDynamicView 'FETCHING'
        @options.itemsReady()


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
  spooled: -> @items_spooled.data()

  # Retrieve a set of all items with phases defined as "WAITING"
  waiting: -> @items_waiting.data()

  # Retrieve a set of all items with phases defined as "WAITING"
  fetching: -> @items.find phase: Phase.FETCHING

  # Retrieve all unfinished ({INITIAL}, {SPOOLED}, {READY}, {FETCHING}, {FETCHED}) items
  unfinished: -> @items.find phase: $in: unfinished

  # Retrieve all items in the specified {ProcessingPhases}s
  inPhases : (phases)  -> @items.find phase: $in: phases

  # Retrieve items in phase {FETCHING} with url matching the given pattern
  processing: (pattern) ->
    @items_fetching
      .branchResultset()
      .find(url : $regex: pattern).data() # possible tuning: make "domain" a field and match per domain without regex

  # @private
  # Save the current state to file
  save: ->
    @store.saveDatabase()

###
  Manage the collection of URLs that are
    scheduled => to be processed in the future
    processing => being processed in form of a {RequestItem}
    visited => completed processing (RequestItem reached phase COMPLETE)
###
class UrlStore extends Mixin
  @with Synchronizer

  # Create a new URL manager
  constructor: (@options) ->
    super()
    @log = @options.log
    @counter = # Maintain counters for URLs per phase to reduce load on db
      scheduled : 0
      visited : 0
      processing : 0
    @urls = new Datastore
      filename: @options.filename + '.urls.db'
    @urls.loadDatabase (err) =>
      @urls.persistence.stopAutocompaction() # Avoid regular flushing to disk
      @urls.ensureIndex {fieldName: 'url', unique:true}, (err) ->
      # Schedule operations to update counters
      @urls.count phase: 'scheduled', (err, count) => @counter.scheduled = count
      @urls.count phase: 'visited', (err, count) => @counter.visited = count
      @urls.count phase: 'processing', (err, count) => @counter.processing = count
      @options.urlsReady()

  # Transition the given URL from 'scheduled' to 'processing'.
  # Inserts a new entry if no scheduled URL has been found.
  # @private
  processing: (url, phase, meta) ->
    update = phase : 'processing'
    update['meta'] = meta if meta
    @urls.update { url:  url, phase: 'scheduled'}, { $set: update},{}, (err, updates) =>
      @counter.processing++
      if updates is 0 # Not found -> wasn't previously scheduled but executed directly
        record =
          url:url
          phase:'processing'
        record['meta'] = meta if meta
        @urls.insert record, ()->
      else
        @counter.scheduled--

  # Returns the number of URLs in given phase
  count: (phase) -> @counter[phase]

  reschedule :  (url) ->
    callback = (err, updates) => @counter.visited++ unless err
    @urls.update { url:  url}, { $set: {phase : 'scheduled'}},{}, callback

  # Add the given URL to the collection of scheduled URLs
  schedule: (url, meta) ->
    record =
      url:url
      phase:'scheduled'
    record['meta'] = meta if meta
    @urls.insert record, (err, result) =>
      if not err
        @log.trace? "Scheduled #{url}", tags:["QueueSystem"]
        @counter.scheduled++

  # Mark a known URL as visited (silently ignores cases of unknown URLs)
  visited: (url) ->
    @urls.update { url:  url}, { $set: {phase : 'visited'}},{}, (err, updates) =>
      if updates > 0 and not err
        @counter.visited++
        @counter.processing--

  # Retrieve the next batch of scheduled URLs
  # @note Needs to run in a fiber
  # @see Synchronizer
  scheduled: (size = 100) ->
    @await @urls.find(phase:'scheduled').limit(size).exec @defer()

  # Save datastore to disk
  save: -> @urls.persistence.compactDatafile()

module.exports = {
  QueueSystem
}
