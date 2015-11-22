class Extension

  constructor: (@descriptor) ->

  apply: (request) ->

  targets: () ->
    @descriptor.extpoints

class ExtensionDescriptor

  constructor: (@name,
                @extpoints = [],
                @description = "Please provide a description") ->

module.exports = {
  Extension
  ExtensionDescriptor
}