# app/views/data/submissions.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Artificial database records representing EMMA submissions as XML.

item ||= @item
name ||= nil
name   = name&.underscore || 'emma_submissions'

xml.instruct!
xml.tag!(name) do
  xml.timestamp DateTime.now
  xml << render('data/details', item: item, name: name)
end
