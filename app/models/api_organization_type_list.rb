# app/models/api_organization_type_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiOrganizationTypeList
#
# @attr [Array<Api::Link>]             links
# @attr [Array<Api::OrganizationType>] organizationTypes
#
# @see https://apidocs.bookshare.org/reference/index.html#_organization_type_list
#
class ApiOrganizationTypeList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :links,             Api::Link
    has_many  :organizationTypes, Api::OrganizationType
  end

end

__loading_end(__FILE__)
