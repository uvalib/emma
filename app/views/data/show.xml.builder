# app/views/data/show.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as XML.

item ||= @item
name ||= @name
name   = name.to_s.underscore

xml.instruct!
xml.tag!(name) do
  # noinspection RubyMismatchedArgumentType
  xml.timestamp DateTime.now
  xml << render('data/details', list: item, name: name)
end
