{QueueConnector} = require './core.queues.coffee'
{CrawlRequest} = require '../CrawlRequest.coffee'
{MockContext} =  require '../util/spec.utils.coffee'

describe  'Queueing extension',  ->
  describe 'QueueConnector', ->
    mockCtx = new MockContext
    it '# can enrich requests for state tracing', ->
      QueueConnector = new QueueConnector
      QueueConnector.initialize mockCtx
      TestRequest = new CrawlRequest 'www.npmjs.com', mockCtx
      QueueConnector.apply TestRequest
      expect(mockCtx.queue.initial().length).to.equal(1)
      expect(mockCtx.queue.spooled().length).to.equal(0)
      TestRequest.spool()
      expect(mockCtx.queue.initial().length).to.equal(0)
      expect(mockCtx.queue.spooled().length).to.equal(1)




