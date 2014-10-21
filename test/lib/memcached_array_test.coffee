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
              memcachedArray.values.should.have.length 1
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
          params.should.have.length 1
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

    describe 'array', ->
      beforeEach (done) ->
        memcachedArray.saveWithValue ['test value 1', 'test value 2'], done

      describe 'methods', ->
        describe 'toString', ->
          context 'sync', ->
            it 'should return the string representation', ->
              memcachedArray.toString().should.equal '[object Object]'
          context 'async', ->
            it 'should return the string representation of the array', (done) ->
              memcachedArray.toString (err, value) ->
                should.not.exist err
                value.should.equal 'test value 1,test value 2'
                done()

        describe 'toLocaleString', ->
          context 'sync', ->
            it 'should return the string representation', ->
              memcachedArray.toLocaleString().should.equal '[object Object]'
          context 'async', ->
            it 'should return the string representation of the array', (done) ->
              memcachedArray.toLocaleString (err, value) ->
                should.not.exist err
                value.should.equal 'test value 1,test value 2'
                done()

        describe 'join', ->
          it 'should join all elements of an array into a string', (done) ->
            memcachedArray.join (err, value) ->
              should.not.exist err
              value.should.equal 'test value 1,test value 2'
              done()

          it 'should join all elements of an array into a string with a separator', (done) ->
            memcachedArray.join '...', (err, value) ->
              should.not.exist err
              value.should.equal 'test value 1...test value 2'
              done()

        describe 'pop', ->
          it 'should remove the last element from an array and return that element', (done) ->
            memcachedArray.pop (err, value) ->
              should.not.exist err
              value.should.equal 'test value 2'
              memcachedArray.values.should.have.length 1
              memcachedArray.values[0].should.equal 'test value 1'
              done()

        describe 'push', ->
          it 'should add one element to the end and return the new length', (done) ->
            memcachedArray.push 'test value 3', (err, value) ->
              should.not.exist err
              value.should.equal 3
              memcachedArray.values.should.have.length 3
              memcachedArray.values[2].should.equal 'test value 3'
              done()

          it 'should add more elements to the end and return the new length', (done) ->
            memcachedArray.push 'test value 3', 'test value 4', (err, value) ->
              should.not.exist err
              value.should.equal 4
              memcachedArray.values.should.have.length 4
              memcachedArray.values[2].should.equal 'test value 3'
              memcachedArray.values[3].should.equal 'test value 4'
              done()

        describe 'concat', ->
          it 'should return a new array comprised of the array with the value provided as argument', (done) ->
            memcachedArray.concat 'test value 3', (err, value) ->
              should.not.exist err
              value.should.have.length 3
              value[2].should.equal 'test value 3'
              memcachedArray.values.should.have.length 2
              done()

          it 'should return a new array comprised of the array with the values provided as arguments', (done) ->
            memcachedArray.concat 'test value 3', 'test value 4', (err, value) ->
              should.not.exist err
              value.should.have.length 4
              value[2].should.equal 'test value 3'
              value[3].should.equal 'test value 4'
              memcachedArray.values.should.have.length 2
              done()

          it 'should return a new array comprised of the array with the array provided as argument', (done) ->
            memcachedArray.concat ['test value 3', 'test value 4'], (err, value) ->
              should.not.exist err
              value.should.have.length 4
              value[2].should.equal 'test value 3'
              value[3].should.equal 'test value 4'
              memcachedArray.values.should.have.length 2
              done()

          it 'should return a new array comprised of the array with the arrays provided as arguments', (done) ->
            memcachedArray.concat ['test value 3', 'test value 4'], ['test value 5', 'test value 6'], (err, value) ->
              should.not.exist err
              value.should.have.length 6
              value[2].should.equal 'test value 3'
              value[3].should.equal 'test value 4'
              value[4].should.equal 'test value 5'
              value[5].should.equal 'test value 6'
              memcachedArray.values.should.have.length 2
              done()

        describe 'reverse', ->
          it 'should reverse an array in place', (done) ->
            memcachedArray.reverse (err, value) ->
              should.not.exist err
              value.should.have.length 2
              value[0].should.equal 'test value 2'
              value[1].should.equal 'test value 1'
              memcachedArray.values.should.have.length 2
              memcachedArray.values[0].should.equal 'test value 2'
              memcachedArray.values[1].should.equal 'test value 1'
              done()

        describe 'shift', ->
          it 'should remove the first element from an array and return that element', (done) ->
            memcachedArray.shift (err, value) ->
              should.not.exist err
              value.should.equal 'test value 1'
              memcachedArray.values.should.have.length 1
              memcachedArray.values[0].should.equal 'test value 2'
              done()

        describe 'unshift', ->
          it 'should add one element to the beginning and return the new length', (done) ->
            memcachedArray.unshift 'test value 3', (err, value) ->
              should.not.exist err
              value.should.equal 3
              memcachedArray.values.should.have.length 3
              memcachedArray.values[0].should.equal 'test value 3'
              done()

          it 'should add more elements to the beginning and return the new length', (done) ->
            memcachedArray.unshift 'test value 3', 'test value 4', (err, value) ->
              should.not.exist err
              value.should.equal 4
              memcachedArray.values.should.have.length 4
              memcachedArray.values[0].should.equal 'test value 3'
              memcachedArray.values[1].should.equal 'test value 4'
              done()

        describe 'slice', ->
          context 'begin omitted', ->
            it 'should return a shallow copy into a new array object', (done) ->
              memcachedArray.slice (err, value) ->
                should.not.exist err
                value.should.have.length 2
                value[0].should.equal 'test value 1'
                value[1].should.equal 'test value 2'
                memcachedArray.values.should.have.length 2
                memcachedArray.values[0].should.equal 'test value 1'
                memcachedArray.values[1].should.equal 'test value 2'
                done()

          context 'begin equals 0', ->
            context 'end omitted', ->
              it 'should return a shallow copy into a new array object', (done) ->
                memcachedArray.slice 0, (err, value) ->
                  should.not.exist err
                  value.should.have.length 2
                  value[0].should.equal 'test value 1'
                  value[1].should.equal 'test value 2'
                  memcachedArray.values.should.have.length 2
                  memcachedArray.values[0].should.equal 'test value 1'
                  memcachedArray.values[1].should.equal 'test value 2'
                  done()

            context 'end equals 0', ->
              it 'should return an empty array', (done) ->
                memcachedArray.slice 0, 0, (err, value) ->
                  should.not.exist err
                  value.should.have.length 0
                  memcachedArray.values.should.have.length 2
                  memcachedArray.values[0].should.equal 'test value 1'
                  memcachedArray.values[1].should.equal 'test value 2'
                  done()

            context 'end > 0', ->
              it 'should return a shallow copy from begin till end into a new array object', (done) ->
                memcachedArray.slice 0, 1, (err, value) ->
                  should.not.exist err
                  value.should.have.length 1
                  value[0].should.equal 'test value 1'
                  memcachedArray.values.should.have.length 2
                  memcachedArray.values[0].should.equal 'test value 1'
                  memcachedArray.values[1].should.equal 'test value 2'
                  done()

            context 'end < 0', ->
              it 'should return a shallow copy from begin till length + end into a new array object', (done) ->
                memcachedArray.push 'test value 3', 'test value 4', (err, value) ->
                  should.not.exist err
                  memcachedArray.slice 0, -1, (err, value) ->
                    should.not.exist err
                    value.should.have.length 3
                    value[0].should.equal 'test value 1'
                    value[1].should.equal 'test value 2'
                    value[2].should.equal 'test value 3'
                    memcachedArray.values.should.have.length 4
                    memcachedArray.values[0].should.equal 'test value 1'
                    memcachedArray.values[1].should.equal 'test value 2'
                    memcachedArray.values[2].should.equal 'test value 3'
                    memcachedArray.values[3].should.equal 'test value 4'
                    done()

          context 'begin > 0', ->
            context 'end omitted', ->
              it 'should return a shallow copy from the begin index into a new array object', (done) ->
                memcachedArray.slice 1, (err, value) ->
                  should.not.exist err
                  value.should.have.length 1
                  value[0].should.equal 'test value 2'
                  memcachedArray.values.should.have.length 2
                  memcachedArray.values[0].should.equal 'test value 1'
                  memcachedArray.values[1].should.equal 'test value 2'
                  done()

            context 'end equals 0', ->
              it 'should return an empty array', (done) ->
                memcachedArray.slice 1, 0, (err, value) ->
                  should.not.exist err
                  value.should.have.length 0
                  memcachedArray.values.should.have.length 2
                  memcachedArray.values[0].should.equal 'test value 1'
                  memcachedArray.values[1].should.equal 'test value 2'
                  done()

            context 'end > 0', ->
              it 'should return a shallow copy from begin till end into a new array object', (done) ->
                memcachedArray.push 'test value 3', (err, value) ->
                  should.not.exist err
                  memcachedArray.slice 1, 2, (err, value) ->
                    should.not.exist err
                    value.should.have.length 1
                    value[0].should.equal 'test value 2'
                    memcachedArray.values.should.have.length 3
                    memcachedArray.values[0].should.equal 'test value 1'
                    memcachedArray.values[1].should.equal 'test value 2'
                    memcachedArray.values[2].should.equal 'test value 3'
                    done()

            context 'end < 0', ->
              it 'should return a shallow copy from begin till length + end into a new array object', (done) ->
                memcachedArray.push 'test value 3', 'test value 4', (err, value) ->
                  should.not.exist err
                  memcachedArray.slice 1, -1, (err, value) ->
                    should.not.exist err
                    value.should.have.length 2
                    value[0].should.equal 'test value 2'
                    value[1].should.equal 'test value 3'
                    memcachedArray.values.should.have.length 4
                    memcachedArray.values[0].should.equal 'test value 1'
                    memcachedArray.values[1].should.equal 'test value 2'
                    memcachedArray.values[2].should.equal 'test value 3'
                    memcachedArray.values[3].should.equal 'test value 4'
                    done()

          context 'begin < 0', ->
            context 'end omitted', ->
              it 'should return a shallow copy of the last begin elements into a new array object', (done) ->
                memcachedArray.push 'test value 3', (err, value) ->
                  should.not.exist err
                  memcachedArray.slice -2, (err, value) ->
                    should.not.exist err
                    value.should.have.length 2
                    value[0].should.equal 'test value 2'
                    value[1].should.equal 'test value 3'
                    memcachedArray.values.should.have.length 3
                    memcachedArray.values[0].should.equal 'test value 1'
                    memcachedArray.values[1].should.equal 'test value 2'
                    memcachedArray.values[2].should.equal 'test value 3'
                    done()

            context 'end equals 0', ->
              it 'should return an empty array', (done) ->
                memcachedArray.slice -2, 0, (err, value) ->
                  should.not.exist err
                  value.should.have.length 0
                  memcachedArray.values.should.have.length 2
                  memcachedArray.values[0].should.equal 'test value 1'
                  memcachedArray.values[1].should.equal 'test value 2'
                  done()

            context 'end > 0', ->
              it 'should return a shallow copy from length + begin to end into a new array object', (done) ->
                memcachedArray.push 'test value 3', (err, value) ->
                  should.not.exist err
                  memcachedArray.slice -2, 2, (err, value) ->
                    should.not.exist err
                    value.should.have.length 1
                    value[0].should.equal 'test value 2'
                    memcachedArray.values.should.have.length 3
                    memcachedArray.values[0].should.equal 'test value 1'
                    memcachedArray.values[1].should.equal 'test value 2'
                    memcachedArray.values[2].should.equal 'test value 3'
                    done()

            context 'end < 0', ->
              it 'should return a shallow copy from length + begin till length + end into a new array object', (done) ->
                memcachedArray.push 'test value 3', 'test value 4', (err, value) ->
                  should.not.exist err
                  memcachedArray.slice -3, -1, (err, value) ->
                    should.not.exist err
                    value.should.have.length 2
                    value[0].should.equal 'test value 2'
                    value[1].should.equal 'test value 3'
                    memcachedArray.values.should.have.length 4
                    memcachedArray.values[0].should.equal 'test value 1'
                    memcachedArray.values[1].should.equal 'test value 2'
                    memcachedArray.values[2].should.equal 'test value 3'
                    memcachedArray.values[3].should.equal 'test value 4'
                    done()

        describe 'splice', ->
          context 'howMany, elements omitted', ->
            context 'index equals 0', ->
              it 'should empty the original array and return an array with original values', (done) ->
                memcachedArray.splice 0, (err, value) ->
                  should.not.exist err
                  value.should.have.length 2
                  value[0].should.equal 'test value 1'
                  value[1].should.equal 'test value 2'
                  memcachedArray.values.should.have.length 0
                  done()
            context 'index > 0', ->
              it 'should remove the elements from index from the original values and return them in an array', (done) ->
                memcachedArray.splice 1, (err, value) ->
                  should.not.exist err
                  value.should.have.length 1
                  value[0].should.equal 'test value 2'
                  memcachedArray.values.should.have.length 1
                  memcachedArray.values[0].should.equal 'test value 1'
                  done()
          context 'elements omitted', ->
            it 'should remove howMany elements from index from the original values and return them in an array', (done) ->
              memcachedArray.push 'test value 3', (err, value) ->
                should.not.exist err
                memcachedArray.splice 1, 1, (err, value) ->
                  should.not.exist err
                  value.should.have.length 1
                  value[0].should.equal 'test value 2'
                  memcachedArray.values.should.have.length 2
                  memcachedArray.values[0].should.equal 'test value 1'
                  memcachedArray.values[1].should.equal 'test value 3'
                  done()

          context 'one element', ->
            it 'should remove howMany elements from index from the original values and add a new element and return them in an array', (done) ->
              memcachedArray.push 'test value 3', (err, value) ->
                should.not.exist err
                memcachedArray.splice 1, 1, 'test value 4', (err, value) ->
                  should.not.exist err
                  value.should.have.length 1
                  value[0].should.equal 'test value 2'
                  memcachedArray.values.should.have.length 3
                  memcachedArray.values[0].should.equal 'test value 1'
                  memcachedArray.values[1].should.equal 'test value 4'
                  memcachedArray.values[2].should.equal 'test value 3'
                  done()

          context 'more elements', ->
            it 'should remove howMany elements from index from the original values and add a new element and return them in an array', (done) ->
              memcachedArray.push 'test value 3', (err, value) ->
                should.not.exist err
                memcachedArray.splice 1, 1, 'test value 4', 'test value 5', (err, value) ->
                  should.not.exist err
                  value.should.have.length 1
                  value[0].should.equal 'test value 2'
                  memcachedArray.values.should.have.length 4
                  memcachedArray.values[0].should.equal 'test value 1'
                  memcachedArray.values[1].should.equal 'test value 4'
                  memcachedArray.values[2].should.equal 'test value 5'
                  memcachedArray.values[3].should.equal 'test value 3'
                  done()

        describe 'sort', ->
          context 'compareFunction omitted', ->
            it 'should sort the elements in place by Unicode code points and return the array', (done) ->
              memcachedArray.push 'test value 0', (err, value) ->
                should.not.exist err
                memcachedArray.sort (err, value) ->
                  should.not.exist err
                  value.should.have.length 3
                  value[0].should.equal 'test value 0'
                  value[1].should.equal 'test value 1'
                  value[2].should.equal 'test value 2'
                  memcachedArray.values.should.have.length 3
                  memcachedArray.values[0].should.equal 'test value 0'
                  memcachedArray.values[1].should.equal 'test value 1'
                  memcachedArray.values[2].should.equal 'test value 2'
                  done()

          context 'compareFunction given', ->
            it 'should sort the elements in place by compareFunction and return the array', (done) ->
              memcachedArray.push 'test value 0', (err, value) ->
                should.not.exist err
                memcachedArray.sort (a, b) ->
                  a < b
                , (err, value) ->
                  console.log err
                  should.not.exist err
                  value.should.have.length 3
                  value[0].should.equal 'test value 2'
                  value[1].should.equal 'test value 1'
                  value[2].should.equal 'test value 0'
                  memcachedArray.values.should.have.length 3
                  memcachedArray.values[0].should.equal 'test value 2'
                  memcachedArray.values[1].should.equal 'test value 1'
                  memcachedArray.values[2].should.equal 'test value 0'
                  done()

        describe 'filter', ->
          it 'should return a new array with all elements that pass the test implemented by the provided function', (done) ->
            memcachedArray.filter (value) ->
              value == 'test value 1'
            , (err, value) ->
              should.not.exist err
              value.should.have.length 1
              value[0].should.equal 'test value 1'
              memcachedArray.values.should.have.length 2
              memcachedArray.values[0].should.equal 'test value 1'
              memcachedArray.values[1].should.equal 'test value 2'
              done()

        describe 'forEach', ->
          context 'thisArg omitted', ->
            it 'sould execute a provided function once per array element', (done) ->
              executed = 0
              memcachedArray.forEach (value, index, array) ->
                index.should.equal executed
                array.should.have.length 2
                array[0].should.equal 'test value 1'
                array[1].should.equal 'test value 2'
                executed++
              , (err, value) ->
                console.log err
                should.not.exist err
                should.not.exist value
                executed.should.equal 2
                memcachedArray.values.should.have.length 2
                memcachedArray.values[0].should.equal 'test value 1'
                memcachedArray.values[1].should.equal 'test value 2'
                done()
          context 'thisArg given', ->
            it 'sould execute a provided function once per array element', (done) ->
              executed = 0
              memcachedArray.forEach (value, index, array) ->
                index.should.equal executed
                array.should.have.length 2
                array[0].should.equal 'test value 1'
                array[1].should.equal 'test value 2'
                this.should.equal 'test'
                executed++
              , 'test', (err, value) ->
                console.log err
                should.not.exist err
                should.not.exist value
                executed.should.equal 2
                memcachedArray.values.should.have.length 2
                memcachedArray.values[0].should.equal 'test value 1'
                memcachedArray.values[1].should.equal 'test value 2'
                done()

        describe 'some', ->
        describe 'every', ->
        describe 'map', ->
        describe 'indexOf', ->
        describe 'lastIndexOf', ->
        describe 'reduce', ->
        describe 'reduceRight', ->

    describe 'getters', ->
      describe 'length', ->

    describe 'setters', ->
      describe 'length', ->
