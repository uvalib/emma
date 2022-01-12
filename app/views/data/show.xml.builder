# app/views/account/show.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as XML.

name    ||= @name
records ||= @item || []

name = name.underscore

xml.instruct!
xml.tag!(name) do
  # noinspection RubyMismatchedArgumentType
  xml.timestamp DateTime.now
  xml << render('data/details', records: records, name: name)
end
