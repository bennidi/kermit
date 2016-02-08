{QueueConnector} = require './core.queues'
{RequestItem} = require '../RequestItem'
{MockContext} =  require '../util/spec.utils'

describe  'Queueing extension',  ->
  describe 'QueueConnector', ->
    mockCtx = new MockContext
    it '# can enrich items for state tracing', ->
      QueueConnector = new QueueConnector
      QueueConnector.initialize mockCtx
      TestRequest = new RequestItem 'www.npmjs.com', mockCtx
      QueueConnector.apply TestRequest
      expect(mockCtx.queue.initial().length).to.equal(1)
      expect(mockCtx.queue.spooled().length).to.equal(0)
      TestRequest.spool()
      expect(mockCtx.queue.initial().length).to.equal(0)
      expect(mockCtx.queue.spooled().length).to.equal(1)
      QueueConnector.shutdown()




