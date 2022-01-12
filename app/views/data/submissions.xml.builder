# app/views/account/submissions.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Artificial database records representing EMMA submissions as XML.

name    ||= nil
records ||= @list

name = name&.underscore || 'emma_submissions'

xml.instruct!
xml.tag!(name) do
  # noinspection RubyMismatchedArgumentType
  xml.timestamp DateTime.now
  xml << render('data/details', records: records, name: name)
end
