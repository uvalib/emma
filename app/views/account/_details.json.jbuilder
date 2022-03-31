# app/views/account/_details.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Details of a local EMMA user account as JSON.

user    ||= @item
columns ||= user&.attribute_names&.reject { |col| col.include?('password') }

json.extract! user, *columns
json.url show_account_url(user, format: :json)
