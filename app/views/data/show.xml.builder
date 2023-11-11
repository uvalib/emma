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
  xml.timestamp DateTime.now
  xml << render('data/details', item: item, name: name)
end
