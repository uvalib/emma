# app/views/account/_details.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Details of an EMMA user account as JSON.

user    ||= @item
columns ||= user&.extended_field_names
columns &&= columns.reject { |col| col.to_s.include?('password') }

json.extract! user, *columns
json.url show_account_url(user, format: :json)
