{Extension} = require './Extension'

describe  'Extension',  ->
  describe 'Extending an extension', ->

    it '# requires a valid descriptor', ->
      class SimpleExtension extends Extension

        constructor: () ->
          super "Phase", "This is a simple extension that does nothing"

      simpleExt = new SimpleExtension
      expect(simpleExt).not.to.be.null()
      expect(simpleExt).to.be.a(SimpleExtension)
      expect(simpleExt).to.be.a(Extension)
      expect(simpleExt).not.to.be.a(Function)

    it '# can merge options', ->
      baseOpts = # Clients can add extensions
        extensions: []
        # Options of each core extension can be customized
        options:
          Filter :
            duplicates : "allow"
          Logging :
            transports: [
                "transport one", "transport two"
              ]

      merged = new Extension().merge baseOpts, {}
      expect(merged.extensions).to.be.empty()
      expect(merged.options.Filter.duplicates).to.equal("allow")
      expect(merged.options.Logging.transports[0]).to.equal("transport one")


