# app/views/manifest/_details.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as XML.

manifest ||= @item
columns    = manifest&.fields&.dup || {}
item_id    = columns.delete(:id)

xml.manifest(id: item_id) do
  columns.each_pair do |name, value|
    xml.tag! name, value
  end
end
