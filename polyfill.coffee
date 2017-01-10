### EXTEND ARRAY with most commonly used lodash methods ###
extendArray = ->
  _ = require 'lodash'

  Array.prototype._map ?= -> _.map @, arguments...
  Array.prototype._orderBy ?= -> _.orderBy @, arguments...
  Array.prototype._flattenDeep ?= -> _.flattenDeep @, arguments...
  Array.prototype._find ?= -> _.find @, arguments...
  Array.prototype._reject ?= -> _.reject @, arguments...
  Array.prototype._remove ?= -> _.remove @, arguments...
  Array.prototype._collect ?= -> _.filter @, arguments...
  Array.prototype._contains ?= -> (_.filter @, arguments...).length > 0
  Array.prototype._reduce ?= -> _.reduce @, arguments[1], arguments[0] # Reverse arguments for better compostion
  Array.prototype.peek ?= -> if _.isEmpty @ then null else @[@length-1]
  Array.prototype.has ?= -> -1 isnt @indexOf arguments[0]


### EXTEND String with string.js ###
extendString = ->
  #stringjs = require 'string'
  #stringjs.extendPrototype()
  String.prototype.hashCode = ->
    hashcode = 0
    for i in [0..@length]
      hashcode = (31 * hashcode + this.charCodeAt(i)) << 0;
    hashcode



extendArray()
extendString()
