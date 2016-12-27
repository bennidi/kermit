{obj} = require '../util/tools'

class User

  @defaults:->
    'User-Agent':'Opera/9.80 (X11; Linux i686; Ubuntu/14.10) Presto/2.12.388 Version/12.16'

  constructor:(properties = {})->
    @properties = obj.overlay User.defaults(), properties
    @id = obj.randomId()
    @cache = {}
    @cookies= {} # todo: cookie jar

  cache:->


module.exports = {
  User
}
