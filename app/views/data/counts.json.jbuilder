# app/views/data/counts.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# A table of EMMA submission fields with a count of each unique value.

list ||= @list

json.timestamp DateTime.now
json.partial! 'data/fields', fields: list
