require '../test_helper'

MemcachedArrayStore = require '../../src/memcached_array_store'

describe 'MemcachedArrayStore', ->
  describe 'constructor', ->
    it 'can be initialized withour parameters', ->
      memcachedArrayStore = new MemcachedArrayStore()
