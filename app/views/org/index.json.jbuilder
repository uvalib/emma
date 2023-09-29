# app/views/org/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA partner organizations as JSON.

list ||= paginator.page_items

json.array! list, partial: 'org/details', as: :org
