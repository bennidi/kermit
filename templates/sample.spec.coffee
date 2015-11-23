describe  'Test suite description',  ->
  describe 'Feature description', ->

    it '# scenario one', ->
      expect("aString").to.be.an.instanceOf(String)
      expect("aString").to.be.a(String)

    it '# scenario two with callback', (done)->
      expect(null).to.be.null()
      expect(false).not.to.be.true()
      expect([1,2,3]).to.contain(1,2)
      expect([1,2,3]).not.to.contain(43)
      process.nextTick () ->
        expect("aString").to.equal('aString')
        done()

