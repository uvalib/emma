# app/views/org/_details.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Details of an EMMA partner organization as XML.

org   ||= @item
columns = org&.fields&.dup || {}
item_id = columns.delete(:id)

xml.org(id: item_id) do
  columns.each_pair do |name, value|
    xml.tag!(name, value)
  end
end
