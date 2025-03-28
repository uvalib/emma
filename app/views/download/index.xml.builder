# app/views/download/index.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA download event records as XML.

list ||= paginator.page_items

xml.instruct!
xml.downloads do
  xml.timestamp DateTime.now
  xml.count     list.size
  list.each do |item|
    xml << render('download/details', item: item)
  end
end
