{Status} = require './CrawlRequest.coffee'
###
 Provide a mechanism to add functionality to the provider of the extension point (=> {Crawler})
 Extension points act as containers for {Extension}s - the primary abstraction for containment
 of processing functionality.
 @abstract (An extension point should be subclassed)
###  
class ExtensionPoint

  # Add list of extensions to the given provider
  @addExtensions : (provider, extensions = []) ->
    for extension in extensions
      ExtensionPoint.extpoint(provider, point).addExtension(extension) for point in extension.targets()
      provider.extensions.push extension
  # Retrieve the {ExtensionPoint} for a given phase from the provider
  @extpoint : (provider, phase) ->
    if !provider.extpoints[phase]?
      throw new Error "Extension point #{phase} does not exists"
    provider.extpoints[phase]
  # Schedule execution of an {ExtensionPoint} for the given request
  @execute : (provider, phase, request) ->
    process.nextTick ExtensionPoint.extpoint(provider, phase).apply, request
    request

  # Construct an extension point
  # @param phase [String] The phase that corresponds to the respective value of {RequestStatus}
  constructor: (@context) ->
    @phase = @constructor.phase # copy from static property
    throw new Error("Please provide phase and description") if !@constructor.phase
    @log = @context.log
    @extensions = []

  # Add an {Extension}s handler for the matching phase
  addExtension: (extension) ->
    @extensions.push extension
    this

  # Helper method to invoke all extensions for processing of a given request
  # @private
  callExtensions : (request) ->
    for extension in @extensions
      try
        # An extension may cancel request processing
        if request.isCanceled()
          return false
        else
          extension.handlers[@phase].call(extension, request)
      catch error
        @log.error error.toString(), { trace: error.stack, tags: [extension.name]}
        request.error(error)
        return false
    true

  # Execute all extensions for the given request
  # @param request [CrawlRequest] The request to be processed
  apply: (request) =>
    @callExtensions(request)
    request

###
Process requests with status {RequestStatus.INITIAL}.
This ExtensionPoint runs: Filtering, Connect to {QueueManager Queueing System}, User extensions
###
class INITIAL extends ExtensionPoint
  @phase = Status.INITIAL

###
Process requests with status "SPOOLED".
Spooled requests are waiting in the {QueueManager} for further processing.
This ExtensionPoint runs: User extensions, {QueueManager}
###
class SPOOLED extends ExtensionPoint
  @phase = Status.SPOOLED

###
Process requests with status "READY".
Request with status "READY" are eligible to be fetched by the {Streamer}.
This ExtensionPoint runs: User extensions.
###
class READY extends ExtensionPoint
  @phase = Status.READY

###
Process requests with status "FETCHING".
Http(s) call to URL is made and response is being streamed.
This ExtensionPoint runs: {RequestStreamer}, User extensions.
###
class FETCHING extends ExtensionPoint
  @phase = Status.FETCHING

###
Process requests with status "FETCHED".
All data has been received and the response is ready for further processing.
This ExtensionPoint runs: User extensions.
###
class FETCHED extends ExtensionPoint
  @phase = Status.FETCHED

###
Process requests with status "COMPLETE".
Response processing is finished. This is the terminal status of a successfully processed
request. This ExtensionPoint runs: User extensions, {Cleanup}
###
class COMPLETE extends ExtensionPoint
  @phase = Status.COMPLETE

###
Process requests with status "ERROR".
{ExtensionPoint}s will set this status if an exception occurs during execution of an {Extension}.
This ExtensionPoint runs: User extensions, {Cleanup}
###
class ERROR extends ExtensionPoint
  @phase = Status.ERROR

###
Process requests with status "CANCELED".
Any extension might cancel a request. Canceled requests are not elligible for further processing
and will be cleaned up. This ExtensionPoint runs: User extensions, {Cleanup}
###
class CANCELED extends ExtensionPoint
  @phase = Status.CANCELED


module.exports = {
  INITIAL
  SPOOLED
  READY
  FETCHING
  FETCHED
  COMPLETE
  CANCELED
  ERROR
  ExtensionPoint
}