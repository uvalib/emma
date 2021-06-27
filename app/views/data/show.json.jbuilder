# app/views/account/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# The contents of a database table as JSON.

name    ||= @name
records ||= @item || []

json.timestamp DateTime.now

json.partial! 'data/details', records: records, name: name
