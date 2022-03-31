# app/views/account/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Show details of a local EMMA user account as JSON.

item ||= @item

json.partial! 'account/details', user: item
