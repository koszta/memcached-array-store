require '../test_helper'

MemcachedArrayStore = require '../../src/memcached_array_store'

describe 'MemcachedArrayStore', ->
  describe 'constructor', ->
    it 'can be initialized without parameters', ->
      memcachedArrayStore = new MemcachedArrayStore()
    it 'can be initialized with memcached parameters', ->
      memcachedArrayStore = new MemcachedArrayStore '127.0.0.1:11211'
  describe 'getArray', ->
    memcachedArrayStore = undefined
    before ->
      memcachedArrayStore = new MemcachedArrayStore()
    beforeEach (done) ->
      memcachedArrayStore.memcached.flush done
    it 'should get an empty array by key if it was not set', (done) ->
      memcachedArrayStore.getArray 'empty', (err, array) ->
        should.not.exist err
        array.getLength (err, length) ->
          should.not.exist err
          length.should.equal 0
          done()
    it 'should get an array by key if it set', (done) ->
      memcachedArrayStore.memcached.set 'nonempty', '[1,2,3]', 1000, (err) ->
        should.not.exist err
        memcachedArrayStore.getArray 'nonempty', (err, array) ->
          should.not.exist err
          array.getLength (err, length) ->
            should.not.exist err
            length.should.equal 3
            array.values[0].should.equal 1
            array.values[1].should.equal 2
            array.values[2].should.equal 3
            done()
