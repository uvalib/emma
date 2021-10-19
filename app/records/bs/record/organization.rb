# app/records/bs/record/organization.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Organization
#
# @attr [Bs::Record::Address]     address
# @attr [Boolean]                 hasOrgAgreement
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  organizationId
# @attr [String]                  organizationName
# @attr [String]                  organizationType
# @attr [String]                  phoneNumber
# @attr [Bs::Record::Sponsor]     primaryContact
# @attr [BsSiteType]              site
# @attr [String]                  subscriptionType
# @attr [String]                  webSite
#
# @see https://apidocs.bookshare.org/membership/index.html#_organization
#
class Bs::Record::Organization < Bs::Api::Record

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :address,          Bs::Record::Address
    has_one   :hasOrgAgreement,  Boolean
    has_many  :links,            Bs::Record::Link
    has_one   :organizationId
    has_one   :organizationName
    has_one   :organizationType
    has_one   :phoneNumber
    has_one   :primaryContact,   Bs::Record::Sponsor
    has_one   :site,             BsSiteType
    has_one   :subscriptionType
    has_one   :webSite
  end

end

__loading_end(__FILE__)
