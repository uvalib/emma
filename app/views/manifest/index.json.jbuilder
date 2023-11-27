# app/views/manifest/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Manifests as JSON.

list ||= paginator.page_items

json.array! list, partial: 'manifest/details', as: :manifest
