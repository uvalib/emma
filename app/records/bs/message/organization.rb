# app/records/bs/message/organization.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::Organization
#
# @attr [Bs::Record::Address]     address
# @attr [Boolean]                 hasOrgAgreement
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  organizationId
# @attr [String]                  organizationName
# @attr [String]                  organizationType
# @attr [String]                  phoneNumber
# @attr [Bs::Record::Sponsor]     primaryContact
# @attr [SiteType]                site
# @attr [String]                  subscriptionType
# @attr [String]                  webSite
#
# @see https://apidocs.bookshare.org/reference/index.html#_organization
#
# NOTE: This duplicates:
# @see Bs::Record::Organization
#
#--
# noinspection DuplicatedCode
#++
class Bs::Message::Organization < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_one   :address,          Bs::Record::Address
    attribute :hasOrgAgreement,  Boolean
    has_many  :links,            Bs::Record::Link
    attribute :organizationId,   String
    attribute :organizationName, String
    attribute :organizationType, String
    attribute :phoneNumber,      String
    has_one   :primaryContact,   Bs::Record::Sponsor
    attribute :site,             SiteType
    attribute :subscriptionType, String
    attribute :webSite,          String
  end

end

__loading_end(__FILE__)
