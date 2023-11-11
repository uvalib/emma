# app/views/org/_details.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Details of an EMMA member organization as JSON.

org     ||= @item
columns ||= org&.attribute_names

json.extract! org, *columns
json.url show_org_url(org, format: :json)
