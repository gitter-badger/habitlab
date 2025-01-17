$ = require 'jquery'
require! 'js-yaml'

{yfy} = require 'cfy'

export S = (pattern) ->
  $(this.$$(pattern))

export SM = (pattern) ->
  $(Polymer.dom(this.root).querySelectorAll(pattern))

export $$$ = (pattern) ->
  Polymer.dom(this.root).querySelectorAll(pattern)

export is_not = (cond) ->
  return !cond

export is_not_equal = (cond, val) ->
  return cond != val

export is_greater_than = (cond, val) ->
  return cond > val

export is_less_than = (cond, val) ->
  return cond < val

export is_greater_than_or_equal_to = (cond, val) ->
  return cond >= val

export is_less_than_or_equal_to = (cond, val) ->
  return cond <= val

export first_elem = (list) ->
  if list? and list.length > 0
    return list[0]
  return

export get_key = (obj, key) ->
  if obj?
    return obj[key]
  return

export get_key_for_first_elem = (list, key) ->
  if list? and list[0]?
    return list[0][key]
  return

export at_index = (list, index) ->
  return list[index]

export xrange = (start, end) ->
  if not end?
    end = start
    start = 0
  return [start til end]

export iterate_object_items = (obj) ->
  [{key: k, value: obj[k]} for k in Object.keys(obj)]

export iterate_object_keys = (obj) ->
  Object.keys(obj)

export iterate_object_values: (obj) ->
  [obj[k] for k in Object.keys(obj)]

export json_stringify = (obj) ->
  JSON.stringify(obj, null, 2)

export yaml_stringify = (obj) ->
  js-yaml.dump JSON.parse JSON.stringify obj

export once_available = yfy (selector, callback) ->
  self = this
  current_result = self.$$(selector)
  if current_result != null
    callback current_result
  else
    setTimeout ->
      self.once_available selector, callback
    , 100

export once_available_multiselect = yfy (selector, callback) ->
  self = this
  current_result = Polymer.dom(self.root).querySelectorAll(selector)
  if current_result.length > 0
    callback current_result
  else
    setTimeout ->
      self.once_available_multiselect selector, callback
    , 100
