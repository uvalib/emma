# app/views/account/index.json.jbuilder
#
# Local EMMA user accounts as JSON.

json.array! @list, partial: 'account/details', as: :user
