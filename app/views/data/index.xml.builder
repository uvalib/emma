# app/views/account/index.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA database tables as XML.

list ||= @list || {}

xml.instruct!
xml.emma_tables do
  # noinspection RubyMismatchedArgumentType
  xml.timestamp DateTime.now
  xml.count     list.size
  xml.tables do
    list.each_pair do |table_name, records|
      table_name = table_name.to_s.underscore
      xml.tag!(table_name) do
        xml << render('data/details', list: records, name: table_name)
      end
    end
  end
end
