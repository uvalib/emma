# app/views/account/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Local EMMA user accounts as JSON.

list ||= @page.page_items

json.array! list, partial: 'account/details', as: :user
