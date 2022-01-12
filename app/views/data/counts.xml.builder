# app/views/data/fields.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# A table of EMMA submission fields with a count of each unique value.

fields ||= @list

xml.instruct!
xml.emma_field_counts do
  # noinspection RubyMismatchedArgumentType
  xml.timestamp DateTime.now
  xml << render('data/fields', fields: fields)
end
