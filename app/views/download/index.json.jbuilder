# app/views/download/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA download event records as JSON.

list ||= paginator.page_items

json.array! list, partial: 'download/details', as: :item
