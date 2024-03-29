# app/views/enrollment/index.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA enrollment requests as XML.

list ||= paginator.page_items

xml.instruct!
xml.enrollments do
  xml.timestamp DateTime.now
  xml.count     list.size
  list.each do |item|
    xml << render('enrollment/details', item: item)
  end
end
