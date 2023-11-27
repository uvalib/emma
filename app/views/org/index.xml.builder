# app/views/org/index.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA member organizations as XML.

list ||= paginator.page_items

xml.instruct!
xml.orgs do
  xml.timestamp DateTime.now
  xml.count     list.size
  list.each do |item|
    xml << render('org/details', org: item)
  end
end
