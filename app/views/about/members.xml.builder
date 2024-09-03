# app/views/about/members.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA member organization listing as XML.

list ||= org_names || []

xml.instruct!
xml.about do
  xml.members do
    list.each do |name|
      xml.member name
    end
  end
end
