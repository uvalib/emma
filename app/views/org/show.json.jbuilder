# app/views/org/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Show details of an EMMA partner organization as JSON.

item ||= @item

json.partial! 'org/details', org: item
