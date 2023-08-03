# app/views/account/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Show details of an EMMA user account as JSON.

item ||= @item

json.partial! 'account/details', user: item
