Memcached = require 'memcached'
MemcachedArray = require './memcached_array'

module.exports = class MemcachedArrayStore
  constructor: ->
    @memcached = new Memcached arguments...
  getArray: (key, callback) ->
    new MemcachedArray this, key, callback
