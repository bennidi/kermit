{RequestItem, Phase} = require('./RequestItem')
{MockContext} = require('./util/spec.utils')
Queue = require('./QueueManager')

describe  'Requests',  ->
  describe 'have a lifecycle reflected as a transitions of states', ->
    log = new MockContext().log

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

    it '# should respond to different errors with corresponding state transitions', ->
      item = new RequestItem 'localhost'
      item.error('TIMEOUT')
      # TODO assertions


    it '# can change its uri', ->
      item = new RequestItem('localhost')
      expect(item.url()).to.equal('localhost')
      item.url('wikipedia.org')
      expect(item.url()).to.equal('wikipedia.org')

    it '# can pretty print it timestamps', ->
      stamps =
        INITIAL : [1243242342]
        TESTING : [1243242342,1243242342,1243242343,1243242345,1243242348]
      expect(RequestItem.stampsToString(stamps).TESTING).to.contain "0ms,1ms,2ms,3ms"
      expect(RequestItem.stampsToString(stamps).INITIAL).to.equal "(1243242342)"

    it '# can pretty print using toString()', ->
      item = new RequestItem('localhost')
      item.state.stamps =
        INITIAL : [1243242342]
        TESTING : [1243242342,1243242342,1243242343,1243242345,1243242348]
      console.log item.toString()
      expect(item.toString()).to.contain "0ms,1ms,2ms,3ms"
