Status = require('./CrawlRequest').Status
ProcessingException = require('./Extension').ProcessingException

# Helper method to invoke all extensions for processing of a given request
callExtensions = (extensions, request)->
  for extension in extensions
    try
      # An extension may modify the request
      #console.info "Executing #{extension.descriptor.name}"
      extension.apply(request)
    catch error
      console.log "Error in extension #{extension.descriptor.name}. Message: #{error.message}"
      # or stop its processing by throwing the right exception
      if (error.type is ProcessingException.types.REJECTED)
        return false
  true

class ExtensionPoint

  constructor: (@phase, @description = "Extension Point has no description") ->
    @extensions = []

  addExtension: (extension) ->
    @extensions.push extension
    this

  apply: (request) ->
    @beforeApply?(request) # Hook for sub-classes to add pre-processing
    result = callExtensions(@extensions, request)
    @afterApply?(request, result) # Hook for sub-classes to add post-processing
    request

class INITIAL extends ExtensionPoint

  @phase = Status.INITIAL

  constructor: () ->
    super Status.INITIAL, "This extension point marks the beginning of a request cycle."


class SPOOLED extends ExtensionPoint

  @phase = Status.SPOOLED

  constructor: () ->
    super Status.SPOOLED, "Extension Point for status #{Status.SPOOLED}"

class FETCHING extends ExtensionPoint

  @phase = Status.FETCHING

  constructor: () ->
    super Status.FETCHING, "Extension Point for status #{Status.FETCHING}"

class READY extends ExtensionPoint

  @phase = Status.READY

  constructor: () ->
    super Status.READY, "Extension Point for status #{Status.READY}"

class FETCHING extends ExtensionPoint

  @phase = Status.FETCHING

  constructor: () ->
    super Status.FETCHING, "Extension Point for status #{Status.FETCHING}"

class FETCHED extends ExtensionPoint

  @phase = Status.FETCHED

  constructor: () ->
    super Status.FETCHED, "Extension Point for status #{Status.FETCHED}"

class COMPLETE extends ExtensionPoint

  @phase = Status.COMPLETE

  constructor: () ->
    super Status.COMPLETE, "Extension Point for status #{Status.COMPLETE}"

class ERROR extends ExtensionPoint

  @phase = Status.ERROR

  constructor: () ->
    super Status.ERROR, "Extension Point for status #{Status.ERROR}"

class CANCELED extends ExtensionPoint

  @phase = Status.CANCELED

  constructor: () ->
    super Status.CANCELED, "Extension Point for status #{Status.CANCELED}"

module.exports =
  ExtensionPoint : ExtensionPoint
  Points:
    INITIAL : INITIAL
    FETCHING : FETCHING
    SPOOLED : SPOOLED
    READY : READY
    FETCHING : FETCHING
    FETCHED : FETCHED
    COMPLETE : COMPLETE
    ERROR : ERROR
    CANCELED : CANCELED
