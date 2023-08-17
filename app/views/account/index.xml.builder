# app/views/account/index.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA user accounts as XML.

list ||= @list || {}

xml.instruct!
xml.users do
  xml.timestamp DateTime.now
  xml.count     list.size
  list.each do |item|
    xml << render('account/details', user: item)
  end
end
