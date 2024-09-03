# app/views/enrollment/_details.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Details of an EMMA enrollment request as XML.

item  ||= @item
columns = item&.fields&.dup || {}
item_id = columns.delete(:id)

xml.enrollment(id: item_id) do
  columns.each_pair do |name, value|
    xml.tag! name, value
  end
end
