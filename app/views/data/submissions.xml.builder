# app/views/account/submissions.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Artificial database records representing EMMA submissions as XML.

name    ||= nil
records ||= @item || []

name = name&.underscore || 'emma_submissions'

xml.instruct!
xml.tag!(name) do
  xml.timestamp DateTime.now
  xml << render('data/details', records: records, name: name)
end
