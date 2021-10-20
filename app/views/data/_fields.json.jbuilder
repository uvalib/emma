# app/views/data/_fields.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# A table of EMMA submission fields with a count of each unique value.

fields ||= nil

# The Firefox formatted display of JSON hosts purely numeric keys to the top of
# the displayed entry.  Appending a space prevents this behavior.
fields &&=
  fields.transform_values do |counts|
    counts.transform_keys do |value|
      value.match?(/^\d+$/) ? "#{value} " : value
    end
  end
fields ||= {}

json.fields fields
