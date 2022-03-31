# app/views/data/submissions.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Artificial database records representing EMMA submissions as JSON.

list ||= @list
name ||= nil

# noinspection RubyMismatchedArgumentType
json.timestamp DateTime.now
json.partial! 'data/details', list: list, name: name
