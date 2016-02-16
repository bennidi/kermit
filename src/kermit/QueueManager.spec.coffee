{RequestItem} = require('./RequestItem')
{QueueSystem} = require('./QueueManager')
{MockContext} = require './util/spec.utils'

describe  'QueueManager',  ->
  describe 'manages items in different states', ->

    it '# has empty queues when newly created', ->
      QueueManager = new QueueSystem
      expect(QueueManager).not.to.be.null()
      expect(QueueManager.items().spooled()).not.to.be.null()
      expect(QueueManager.items().spooled().length).to.equal(0)
