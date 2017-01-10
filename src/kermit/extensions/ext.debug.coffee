{obj} = require '../util/tools'
_ = require 'lodash'
{Extension} = require '../Extension'

class FullRequestTrace extends Extension

  constructor:->
    super()
    @on INITIAL : (item) =>
      @log.debug? "#{item.phase()}:#{item.url()}", {item}

      item.onChange 'phase', (item) => @log.debug? "#{item.phase()}:#{item.url()}", {item}

module.exports = {
  FullRequestTrace
}
