# app/views/data/fields.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# A table of EMMA submission fields with a count of each unique value.

list ||= @list

xml.instruct!
xml.emma_field_counts do
  xml.timestamp DateTime.now
  xml << render('data/fields', fields: list)
end
