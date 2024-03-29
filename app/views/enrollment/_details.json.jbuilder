# app/views/enrollment/_details.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Details of an EMMA enrollment request as JSON.

item    ||= @item
columns ||= item&.extended_field_names

json.extract! item, *columns
json.url show_enrollment_url(item, format: :json)
