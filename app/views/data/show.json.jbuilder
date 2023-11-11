# app/views/data/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as JSON.

item ||= @item
name ||= @name

json.timestamp DateTime.now
json.partial! 'data/details', item: item, name: name
