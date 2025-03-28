# app/views/download/show.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Show details of a EMMA download event record as XML.

item ||= @item

xml.instruct!
xml.downloads do
  xml.timestamp DateTime.now
  xml << render('download/details', item: item)
end
