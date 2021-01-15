# app/views/account/show.json.jbuilder
#
# Show details of a local EMMA user account as JSON.

json.partial! 'account/details', user: @item
