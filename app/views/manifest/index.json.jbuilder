# app/views/manifest/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Manifests as JSON.

list ||= @list

json.array! list, partial: 'manifest/details', as: :manifest
