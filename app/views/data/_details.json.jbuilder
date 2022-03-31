# app/views/data/_details.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as JSON.

list ||= nil
list   = list.is_a?(Array) ? list.dup : Array.wrap(list)

schema_key, column_types = (list.shift || { schema: {} }).first

json.count   list.size
json.set!    schema_key, column_types
json.records list
