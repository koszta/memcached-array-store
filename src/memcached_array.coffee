EventEmitter = require('events').EventEmitter

module.exports = class MemcachedArray extends EventEmitter
  constructor: (@store, @key, callback = ->) ->
    @values = []
    @initialize callback
    this
  serialize: (value = @values) ->
    JSON.stringify value
  getterName: (key) ->
    "get#{key.charAt(0).toUpperCase()}#{key.slice(1)}"
  setterName: (key) ->
    "set#{key.charAt(0).toUpperCase()}#{key.slice(1)}"
  initialize: (callback) ->
    @store.memcached.add @key, @serialize(), 1000, (err) =>
      return callback err if err? && !err.notStored
      @sync (err) =>
        return callback err if err?
        callback null, this
        @emit 'initialize', this
  sync: (callback = ->) ->
    @store.memcached.gets @key, (err, data) =>
      if data?
        value = data[@key]
        @cas = data.cas
      try
        throw err if err?
        if value?
          @values = JSON.parse value
        callback null, this
        @emit 'sync', this
      catch err
        callback err
  save: (callback) ->
    @saveWithValue @values, callback
  saveWithValue: (value, callback = ->) ->
    @store.memcached.cas @key, @serialize(value), @cas, 1000, (err, found) =>
      return callback err if err?
      unless found
        err = new Error 'value changed in the meanwhile'
        err.casChange = true
        return callback err
      @sync (err) =>
        return callback err if err?
        callback null, this
        @emit 'save', this
  perform: (key, params..., callback) ->
    @sync (err) =>
      return callback err if err?
      array = @values.slice 0
      returnValue = array[key] params...
      @saveWithValue array, (err) =>
        if err?
          if err.casChange
            return @perform key, params..., callback
          else
            return callback err
        callback null, returnValue
        @emit key, this, params..., returnValue
  performGetter: (key, callback) ->
    @sync (err) =>
      return callback err if err?
      array = @values.slice 0
      value = array[key]
      callback null, value
      @emit @getterName(key), this, value
  performSetter: (key, value, callback) ->
    @sync (err) =>
      return callback err if err?
      array = @values.slice 0
      array[key] = value
      @saveWithValue array, (err) =>
        if err?
          if err.casChange
            return @performSetter key, value, callback
          else
            return callback err
        callback null, value
        @emit @setterName(key), this, value

Object.getOwnPropertyNames(Array::).forEach (key) ->
  return if key in ['constructor', 'toString']
  switch typeof Array::[key]
    when 'function'
      MemcachedArray::[key] = (params..., callback) ->
        console.log key, params..., callback
        @perform key, params..., callback
    else
      MemcachedArray::[MemcachedArray::getterName(key)] = (callback) ->
        @performGetter key, callback
      MemcachedArray::[MemcachedArray::setterName(key)] = (value, callback) ->
        @performSetter key, value, callback
