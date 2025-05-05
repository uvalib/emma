# app/views/download/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Show details of a EMMA download event record as JSON.

item ||= @item

json.partial! 'download/details', item: item
