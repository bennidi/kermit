###

  A {RequestItem} is always in one of the following processing phases.
  Each item starts with phase {ProcessingPhase.INITIAL}
  From phase {INITIAL} it transitions forward while being processed by the {Extension}s
  that handle items of that particular phase. The following diagram illustrate the possible
  phase transitions with the ordinary flow {INITIAL} -> {SPOOLED} -> {READY} -> {FETCHING} -> {FETCHED} -> {COMPLETE}.
  Any item may also end in phases {CANCELED} or {ERROR} depending on the logic of the {Extension}s

```txt

  .-------------.
 |   INITIAL   |
 |-------------|
 | Unprocessed |
 |             |
 '-------------'   \
        |           \
        |            \
        |             v
        v             .--------------------.
 .-------------.      |  ERROR | CANCELED  |      .-----------.
 |  SPOOLED    |      |--------------------|      | COMPLETE  |
 |-------------|  --->| - Error            |      |-----------|
 | Waiting for |      | - Duplicate        |      | Done!     |
 | free slot   |      | - Blacklisted etc. |      |           |
 '-------------'      '--------------------'      '-----------'
        |             ^         ^          ^            ^
        |            /          |           \           |
        |           /           |            \          |
        v          /                          \         |
 .-------------.         .-------------.          .-----------.
 |    READY    |         |  FETCHING   |          |  FETCHED  |
 |-------------|         |-------------|          |-----------|
 | Ready for   |-------->| Request     |--------->| Content   |
 | fetching    |         | streaming   |          | received  |
 '-------------'         '-------------'          '-----------'
```

@see Crawler for a list of core extensions applied at each phase
@see ProcessingPhase and its subclasses for descriptions of
@abstract
###
class ProcessingPhase
  # @property [String] See {INITIAL}
  @INITIAL:'INITIAL'
  # @property [String] See {SPOOLED}
  @SPOOLED:'SPOOLED'
  # @property [String] See {READY}
  @READY:'READY'
  # @property [String] See {FETCHING}
  @FETCHING:'FETCHING'
  #@property [String] See {FETCHED}
  @FETCHED:'FETCHED'
  # @property [String] See {COMPLETE}
  @COMPLETE:'COMPLETE'
  # @property [String] See {ERROR}
  @ERROR:'ERROR'
  # @property [String] See {CANCELED}
  @CANCELED:'CANCELED'
  # @property [Array<String>] Collection of all defined phase
  @ALL: ['INITIAL', 'SPOOLED','READY','FETCHING','FETCHED','COMPLETE','ERROR','CANCELED']

  constructor: ->
    @name = constructor.name

  # Retrieve the expected succeeding phase for the given phase
  @follower : (phase) ->
    switch phase
      when 'INITIAL' then 'SPOOLED'
      when 'SPOOLED' then 'READY'
      when 'READY' then 'FETCHING'
      when 'FETCHING' then 'FETCHED'
      when 'FETCHED' then 'COMPLETE'
      when 'COMPLETE' then 'COMPLETE'
      when 'CANCELED' then 'CANCELED'
      when 'ERROR' then 'ERROR'
      else throw new Error "Unknown phase #{phase} has no follower"

  # Retrieve the preceeding phase for the given phase
  @predecessor : (phase) ->
    switch phase
      when 'INITIAL' then 'INITIAL'
      when 'SPOOLED' then 'INITIAL'
      when 'READY' then 'SPOOLED'
      when 'FETCHING' then 'READY'
      when 'FETCHED' then 'FETCHING'
      when 'COMPLETE' then 'FETCHED'
      when 'CANCELED' then ['INITIAL', 'SPOOLED', 'READY', 'FETCHED']
      when 'ERROR' then ['INITIAL', 'SPOOLED', 'READY', 'FETCHING', 'FETCHED']
      else throw new Error "Unknown phase #{phase} has no predecessor"

###
Process items with phase INITIAL.
This ProcessingPhase runs: Filtering, Connect to {QueueManager Queueing System}, User extensions
###
class INITIAL extends ProcessingPhase

###
Process items with phase "SPOOLED".
Spooled items are waiting in the {QueueManager} for further processing.
This ProcessingPhase runs: User extensions, {QueueManager}
###
class SPOOLED extends ProcessingPhase

###
Process items with phase "READY".
Request with phase "READY" are eligible to be fetched by the {Streamer}.
This ProcessingPhase runs: User extensions.
###
class READY extends ProcessingPhase

###
Process items with phase "FETCHING".
Http(s) call to URL is made and response is being streamed.
This ProcessingPhase runs: {RequestStreamer}, User extensions.
###
class FETCHING extends ProcessingPhase

###
Process items with phase "FETCHED".
All data has been received and the response is ready for further processing.
This ProcessingPhase runs: User extensions.
###
class FETCHED extends ProcessingPhase

###
Process items with phase "COMPLETE".
Response processing is finished. This is the terminal phase of a successfully processed
item. This ProcessingPhase runs: User extensions, {Cleanup}
###
class COMPLETE extends ProcessingPhase

###
Process items with phase "ERROR".
{ExtensionPoint}s will set this phase if an exception occurs during execution of an {Extension}.
This ProcessingPhase runs: User extensions, {Cleanup}
###
class ERROR extends ProcessingPhase

###
Process items with phase "CANCELED".
Any extension might cancel a item. Canceled items are not elligible for further processing
and will be cleaned up. This ProcessingPhase runs: User extensions, {Cleanup}
###
class CANCELED extends ProcessingPhase

module.exports = {
  Phase : ProcessingPhase
}