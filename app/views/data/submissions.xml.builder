# app/views/data/submissions.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Artificial database records representing EMMA submissions as XML.

list ||= @list
name ||= nil
name   = name&.underscore || 'emma_submissions'

xml.instruct!
xml.tag!(name) do
  # noinspection RubyMismatchedArgumentType
  xml.timestamp DateTime.now
  xml << render('data/details', list: list, name: name)
end
