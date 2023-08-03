# app/views/manifest/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Show details of a manifest as JSON.

item ||= @item

json.partial! 'manifest/details', manifest: item
