# app/views/data/counts.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# A table of EMMA submission fields with a count of each unique value.

fields ||= @list

# noinspection RubyMismatchedArgumentType
json.timestamp DateTime.now
json.partial! 'data/fields', fields: fields
