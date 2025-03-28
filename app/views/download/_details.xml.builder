# app/views/download/_details.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Details of an EMMA download event record as XML.

item  ||= @item
columns = item&.fields&.dup || {}
item_id = columns.delete(:id)

xml.download(id: item_id) do
  columns.each_pair do |name, value|
    xml.tag! name, value
  end
end
