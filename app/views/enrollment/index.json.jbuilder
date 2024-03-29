# app/views/enrollment/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA enrollment requests as JSON.

list ||= paginator.page_items

json.array! list, partial: 'enrollment/details', as: :item
