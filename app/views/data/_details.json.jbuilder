# app/views/data/_details.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as JSON.

records ||= nil

records = records&.dup || []
schema_key, column_types = (records.shift || { schema: {} }).first

json.count   records.size
json.set!    schema_key, column_types
json.records records
