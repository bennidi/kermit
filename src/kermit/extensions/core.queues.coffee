{Phase} = require '../RequestItem'
storage = require '../QueueSystem'
{Extension} = require '../Extension'
RateLimiter = require('limiter').RateLimiter
{obj} = require '../util/tools'
_ = require 'lodash'

###
  The Queue Connector propagates request phase transitions to the
  {QueueSystem} such that they are reflected instantly.
###
class QueueConnector extends Extension

  # @nodoc
  constructor: ->
    super()
      # Enrich each item with methods that propagate its
      # state transitions to the queue system
    @on INITIAL : (item) ->
        item.onChange 'phase', (item) => @qs.items().update item
        @qs.initial item


# Process items that have been SPOOLED for fetching.
# Takes care that concurrency and rate limits are met.
class QueueWorker extends Extension

  @defaultOpts = ->
    limits : [
        pattern : /.*/
        to : 5
        per : 'second' # 'second', 'minute', 'day', or a number of milliseconds
        max : 5
    ]

  # https://www.npmjs.com/package/simple-rate-limiter
  constructor: (opts = {}) ->
    super {}
    @opts = obj.merge QueueWorker.defaultOpts(), opts

  # @nodoc
  initialize: (context) ->
    super context
    @items = context.items # Request object is resolved from shared item map
    @limits = new RateLimits @opts.limits, @context.log, @qs # Rate limiting is applied here
    @batch = [] # Local batch of items to be put into READY state
    @onStart =>
      @log.debug? "Starting QueueWorker"
      @pump = setInterval @processRequests, 100
    @onStop =>
      @log.debug? "Stopping QueueWorker"
      clearInterval @pump

  # This is run at intervals to process waiting items
  # @private
  processRequests : =>
    # Transition SPOOLED items into READY state unless parallelism threshold is reached
    @proceed @items[item.id] for item in @localBatch()

  # @nodoc
  localBatch: ->
    currentBatch = _.filter @batch, (item) -> item.phase is 'SPOOLED'
    if not _.isEmpty currentBatch then currentBatch else @batch = @qs.items().spooled()

  # @nodoc
  proceed : (item) ->
    item.ready() if @limits.isAllowed item.url()

###
  Wrapper for rate limit configurations passed as options to the {QueueWorker}
  @private
  @nodoc
###
class RateLimits

  constructor: (limits =[], @log, qs) ->
    @limits = (new Limit limitDef, qs for limitDef in limits)

  # Check whether all applicable {Limit}s allow this URL to pass
  isAllowed : (url) ->
    for limit in @limits
      return limit.isAllowed() if limit.matches url
    throw new Error "No limit matched #{url}"

###

  Internal wrapper around RateLimiter library

  @nodoc
  @private
###
class Limit

  # @nodoc
  constructor: (@def, @qs) ->
    @regex = @def.pattern
    @limiter = new RateLimiter @def.to , @def.per

  # @nodoc
  isAllowed: ->
    @limiter.tryRemoveTokens(1) and @qs.items().processing(@regex).length < @def.max

  # @nodoc
  matches: (url) ->
    url.match @regex

module.exports = {
  QueueConnector
  QueueWorker
}
