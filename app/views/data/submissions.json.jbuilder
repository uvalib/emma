# app/views/account/submissions.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Artificial database records representing EMMA submissions as JSON.

name    ||= nil
records ||= @list

# noinspection RubyMismatchedArgumentType
json.timestamp DateTime.now
json.partial! 'data/details', records: records, name: name
