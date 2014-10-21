MemcachedArrayStore = require '../../src/memcached_array_store'
MemcachedArray = require '../../src/memcached_array'

memcachedArrayStore = new MemcachedArrayStore()

describe 'MemcachedArray', ->
  beforeEach (done) ->
    memcachedArrayStore.memcached.flush done

  describe 'constructor', ->
    it 'can be initialized with memcache array store, key, callback', (done) ->
      memcachedArray = new MemcachedArray memcachedArrayStore, 'empty', (err, data) ->
        should.not.exist err
        data.should.equal memcachedArray
        memcachedArray.getLength (err, length) ->
          should.not.exist err
          length.should.equal 0
          done()
    it 'should emit initialize event', (done) ->
      memcachedArray = new MemcachedArray memcachedArrayStore, 'empty'
      memcachedArray.once 'initialize', (data) ->
        data.should.equal memcachedArray
        done()
    it 'should emit sync event', (done) ->
      memcachedArray = new MemcachedArray memcachedArrayStore, 'empty'
      memcachedArray.once 'sync', (data) ->
        data.should.equal memcachedArray
        done()

  describe 'getterName', ->
    it 'should create a getter name for key', ->
      MemcachedArray::getterName('test').should.equal 'getTest'

  describe 'setterName', ->
    it 'should create a setter name for key', ->
      MemcachedArray::setterName('test').should.equal 'setTest'

  context 'initialized', ->
    memcachedArray = null
    beforeEach (done) ->
      memcachedArray = new MemcachedArray memcachedArrayStore, 'test', done

    describe 'serialize', ->
      it 'should serialize @values', ->
        memcachedArray.serialize().should.equal '[]'
      it 'should serialize a specified value', ->
        memcachedArray.serialize(['something']).should.equal '["something"]'

    describe 'sync', ->
      it 'should fetch the latest data with cas from memcached', (done) ->
        memcachedArrayStore.memcached.set 'test', '["this has been changed"]', 1000, (err) ->
          should.not.exist err
          memcachedArrayStore.memcached.gets 'test', (err, data) ->
            should.not.exist err
            data.test.should.equal '["this has been changed"]'
            cas = data.cas
            should.exist cas
            memcachedArray.sync (err, data) ->
              should.not.exist err
              data.should.equal memcachedArray
              memcachedArray.values.length.should.equal 1
              memcachedArray.values[0].should.equal 'this has been changed'
              memcachedArray.cas.should.equal cas
              done()
      it 'should emit sync event', (done) ->
        memcachedArray.sync()
        memcachedArray.once 'sync', (data) ->
          data.should.equal memcachedArray
          done()

    describe 'saveWithValue', ->
      it 'should save the array with a new value to memcached', (done) ->
        memcachedArray.saveWithValue ['hi'], (err, data) ->
          should.not.exist err
          data.should.equal memcachedArray
          memcachedArrayStore.memcached.get 'test', (err, value) ->
            should.not.exist err
            value.should.equal '["hi"]'
            done()
      it 'should emit save event', (done) ->
        memcachedArray.saveWithValue ['hi']
        memcachedArray.once 'save', (data) ->
          data.should.equal memcachedArray
          done()
      it 'should emit sync event', (done) ->
        memcachedArray.saveWithValue ['hi']
        memcachedArray.once 'sync', (data) ->
          data.should.equal memcachedArray
          done()
      it 'should be thread safe', (done) ->
        memcachedArrayStore.memcached.set 'test', '["this has been changed"]', 1000, (err) ->
          should.not.exist err
        memcachedArray.saveWithValue ['hi'], (err, data) ->
          should.exist err
          err.message.should.equal 'value changed in the meanwhile'
          err.casChange.should.be.true
          done()

    describe 'save', ->
      it 'should save the array to memcached', (done) ->
        memcachedArray.getLength (err, length) ->
          should.not.exist err
          length.should.equal 0
          memcachedArray.values.push 'hi'
          memcachedArray.save (err, data) ->
            should.not.exist err
            data.should.equal memcachedArray
            memcachedArrayStore.memcached.get 'test', (err, value) ->
              should.not.exist err
              value.should.equal '["hi"]'
              done()
      it 'should emit save event', (done) ->
        memcachedArray.save()
        memcachedArray.once 'save', (data) ->
          data.should.equal memcachedArray
          done()
      it 'should emit sync event', (done) ->
        memcachedArray.save()
        memcachedArray.once 'sync', (data) ->
          data.should.equal memcachedArray
          done()
      it 'should be thread safe', (done) ->
        memcachedArrayStore.memcached.set 'test', '["this has been changed"]', 1000, (err) ->
          should.not.exist err
        memcachedArray.values.push 'hi'
        memcachedArray.save (err, data) ->
          should.exist err
          err.message.should.equal 'value changed in the meanwhile'
          err.casChange.should.be.true
          done()

    describe 'perform', ->
      it 'should perform an array method on values', (done) ->
        memcachedArray.perform 'push', 'hi', (err, value) ->
          should.not.exist err
          value.should.equal 1
          memcachedArrayStore.memcached.get 'test', (err, value) ->
            should.not.exist err
            value.should.equal '["hi"]'
            done()
      it 'should emit the name of method', (done) ->
        memcachedArray.perform 'push', 'hi', ->
        memcachedArray.once 'push', (data, params..., value) ->
          data.should.equal memcachedArray
          params.length.should.equal 1
          params[0].should.equal 'hi'
          value.should.equal 1
          done()
      it 'should emit save event', (done) ->
        memcachedArray.perform 'push', 'hi', ->
        memcachedArray.once 'save', (data) ->
          data.should.equal memcachedArray
          done()
      it 'should emit sync event', (done) ->
        memcachedArray.perform 'push', 'hi', ->
        memcachedArray.once 'sync', (data) ->
          data.should.equal memcachedArray
          done()
      it 'should be thread safe', (done) ->
        memcachedArray.perform 'push', 'hi', (err, value) ->
          should.not.exist err
          value.should.equal 2
          memcachedArrayStore.memcached.get 'test', (err, value) ->
            should.not.exist err
            value.should.equal '["this has been changed","hi"]'
            done()
        memcachedArrayStore.memcached.set 'test', '["this has been changed"]', 1000, (err) ->
          should.not.exist err

    describe 'performGetter', ->
      it 'should perform a getter on values', (done) ->
        memcachedArray.performGetter 'length', (err, value) ->
          should.not.exist err
          value.should.equal 0
          done()
      it 'should emit the name of getter', (done) ->
        memcachedArray.performGetter 'length', ->
        memcachedArray.once 'getLength', (data, value) ->
          data.should.equal memcachedArray
          value.should.equal 0
          done()
      it 'should not emit save event', (done) ->
        memcachedArray.performGetter 'length', ->
        memcachedArray.once 'save', (data) ->
          done new Error 'emitted save event'
        setTimeout ->
          done()
        , 50
      it 'should emit sync event', (done) ->
        memcachedArray.performGetter 'length', ->
        memcachedArray.once 'sync', (data) ->
          data.should.equal memcachedArray
          done()
      it 'should sync to the latest version', (done) ->
        memcachedArrayStore.memcached.set 'test', '["this has been changed"]', 1000, (err) ->
          should.not.exist err
        memcachedArray.performGetter 'length', (err, value) ->
          should.not.exist err
          value.should.equal 1
          done()

    describe 'performSetter', ->
      it 'should perform a setter on values', (done) ->
        memcachedArray.performSetter 'length', 1, (err, value) ->
          should.not.exist err
          value.should.equal 1
          done()
      it 'should emit the name of setter', (done) ->
        memcachedArray.performSetter 'length', 1, ->
        memcachedArray.once 'setLength', (data, value) ->
          data.should.equal memcachedArray
          value.should.equal 1
          done()
      it 'should emit save event', (done) ->
        memcachedArray.performSetter 'length', 1, ->
        memcachedArray.once 'save', (data) ->
          data.should.equal memcachedArray
          done()
      it 'should emit sync event', (done) ->
        memcachedArray.performSetter 'length', 1, ->
        memcachedArray.once 'sync', (data) ->
          data.should.equal memcachedArray
          done()
      it 'should be thread safe', (done) ->
        memcachedArray.performSetter 'length', 1, (err, value) ->
          should.not.exist err
          value.should.equal 1
          memcachedArrayStore.memcached.get 'test', (err, value) ->
            should.not.exist err
            value.should.equal '["this has been changed"]'
            done()
        memcachedArrayStore.memcached.set 'test', '["this has been changed", "with this"]', 1000, (err) ->
          should.not.exist err
