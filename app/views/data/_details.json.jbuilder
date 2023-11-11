# app/views/data/_details.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as JSON.

item ||= nil
item   = item.is_a?(Array) ? item.dup : Array.wrap(item)

schema_key, column_types = (item.shift || { schema: {} }).first

json.count   item.size
json.set!    schema_key, column_types
json.records item
