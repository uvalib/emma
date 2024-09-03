# app/views/about/members.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA member organization listing.

list ||= org_names || []

json.timestamp DateTime.now
json.count     list.size

json.set! :about do
  json.set! :members, list
end
