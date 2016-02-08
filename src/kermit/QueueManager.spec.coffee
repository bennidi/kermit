{RequestItem} = require('./RequestItem')
Queue = require('./QueueManager').QueueManager
{MockContext} = require './util/spec.utils'

describe  'QueueManager',  ->
  describe 'manages items in different states', ->

    it '# has empty queues when newly created', ->
      QueueManager = new Queue
      expect(QueueManager).not.to.be.null()
      expect(QueueManager.spooled()).not.to.be.null()
      expect(QueueManager.spooled().length).to.equal(0)
