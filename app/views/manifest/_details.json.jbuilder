# app/views/manifest/_details.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# A bulk operations manifest as JSON.

manifest ||= @item
columns  ||= manifest&.extended_field_names

json.extract! manifest, *columns
json.url manifest_index_url(manifest, format: :json)
