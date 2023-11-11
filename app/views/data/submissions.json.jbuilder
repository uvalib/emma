# app/views/data/submissions.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Artificial database records representing EMMA submissions as JSON.

item ||= @item
name ||= nil
name   = name&.underscore || 'emma_submissions'

json.timestamp DateTime.now
json.partial! 'data/details', item: item, name: name
