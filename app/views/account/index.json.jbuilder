# app/views/account/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA user accounts as JSON.

list ||= paginator.page_items

json.array! list, partial: 'account/details', as: :user
