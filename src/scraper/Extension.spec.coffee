cherry = require './cherry.modules'

describe  'Extension',  ->
  describe 'Extending an extension', ->

    it '# requires a valid descriptor', ->
      class SimpleExtension extends cherry.extensions.Extension

        constructor: () ->
          super new cherry.extensions.ExtensionDescriptor "Phase", "This is a simple extension that does nothing"

      simpleExt = new SimpleExtension
      expect(simpleExt).not.to.be.null()
      expect(simpleExt).to.be.a(SimpleExtension)
      expect(simpleExt).to.be.a(cherry.extensions.Extension)
      expect(simpleExt).not.to.be.a(Function)

    it '# fails when no descriptor is provided', ->
      class ExtensionWithoutDescriptor extends cherry.extensions.Extension

      try
        brokenExt = new ExtensionWithoutDescriptor
        expect(false).to.be.true() # this code should not be reached
      catch error



