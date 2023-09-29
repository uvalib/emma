# app/views/org/show.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Show details of an EMMA partner organization as XML.

item ||= @item

xml.instruct!
xml.orgs do
  xml.timestamp DateTime.now
  xml << render('org/details', org: item)
end
