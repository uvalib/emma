# app/views/data/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA database tables as JSON.

list ||= @list || {}

# noinspection RubyMismatchedArgumentType
json.timestamp DateTime.now
json.count     list.size

json.tables do
  list.each_pair do |table_name, records|
    json.set! table_name do
      json.partial! 'data/details', list: records, name: table_name
    end
  end
end
