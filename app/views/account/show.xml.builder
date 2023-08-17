# app/views/account/show.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Show details of an EMMA user account as XML.

item ||= @item

xml.instruct!
xml.users do
  xml.timestamp DateTime.now
  xml << render('account/details', user: item)
end
