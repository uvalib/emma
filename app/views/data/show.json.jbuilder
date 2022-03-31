# app/views/account/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as JSON.

item ||= @item
name ||= @name

# noinspection RubyMismatchedArgumentType
json.timestamp DateTime.now
json.partial! 'data/details', list: item, name: name
