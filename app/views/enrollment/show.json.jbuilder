# app/views/enrollment/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Show details of an EMMA enrollment request as JSON.

item ||= @item

json.partial! 'enrollment/details', item: item
