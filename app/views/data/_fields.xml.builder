# app/views/data/_fields.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# A table of EMMA submission fields with a count of each unique value.

fields ||= {}

xml.fields do
  fields.each_pair do |field, counts|
    xml.tag!(field, total: counts.values.sum) do
      counts.each_pair do |value, count|
        xml.item value, count: count
      end
    end
  end
end
