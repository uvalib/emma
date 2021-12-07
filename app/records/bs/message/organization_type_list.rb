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
# @see https://apidocs.bookshare.org/membership/index.html#_organization_type_list
#
class Bs::Message::OrganizationTypeList < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::OrganizationType

  schema do
    has_many :links,             Bs::Record::Link
    has_many :organizationTypes, LIST_ELEMENT
  end

end

__loading_end(__FILE__)
