{RequestItem, Phase} = require('./RequestItem')

describe  'Requests',  ->
  describe 'have a lifecycle reflected as a transitions of states', ->

    it '# is in state INITIAL when newly instantiated', ->
      expect(RequestItem).not.to.be.null()
      TestRequest = new RequestItem 'localhost',
      expect(TestRequest).not.to.be.null()
      expect(TestRequest.phase()).to.equal(Phase.INITIAL)
      expect(TestRequest.parents()).to.equal(0)

    it '# should notify state listeners when changes occurr', ->
      receivedPhaseChanges = []
      TestRequest = new RequestItem 'localhost'
        .onChange 'phase', (item) ->
          receivedPhaseChanges.push item.phase()
      TestRequest.phase('STATE1')
      TestRequest.phase('STATE2')
      TestRequest.phase('STATE3')
      expect(receivedPhaseChanges).to.contain 'STATE1','STATE2','STATE3'


    it '# can change its uri', ->
      item = new RequestItem('localhost')
      expect(item.url()).to.equal('localhost')
      item.url('wikipedia.org')
      expect(item.url()).to.equal('wikipedia.org')
