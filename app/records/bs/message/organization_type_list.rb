# app/records/bs/message/organization_type_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::OrganizationTypeList
#
# @attr [Array<Bs::Record::Link>]             links
# @attr [Array<Bs::Record::OrganizationType>] organizationTypes
#
# @see https://apidocs.bookshare.org/reference/index.html#_organization_type_list
#
class Bs::Message::OrganizationTypeList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many :links,             Bs::Record::Link
    has_many :organizationTypes, Bs::Record::OrganizationType
  end

end

__loading_end(__FILE__)
