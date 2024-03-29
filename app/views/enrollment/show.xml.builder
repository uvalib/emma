# app/views/enrollment/show.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Show details of an EMMA enrollment request as XML.

item ||= @item

xml.instruct!
xml.enrollments do
  xml.timestamp DateTime.now
  xml << render('enrollment/details', item: item)
end
