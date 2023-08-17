# app/views/account/_details.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Details of an EMMA user account as XML.

user  ||= @item
columns = user&.fields&.dup || {}
item_id = columns.delete(:id)

xml.user(id: item_id) do
  columns.each_pair do |name, value|
    xml.tag!(name, value)
  end
end
