# app/models/api_organization.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/organization'

# ApiOrganization
#
# @attr [Api::Address]     address
# @attr [Boolean]          hasOrgAgreement
# @attr [Array<Api::Link>] links
# @attr [String]           organizationId
# @attr [String]           organizationName
# @attr [String]           organizationType
# @attr [String]           phoneNumber
# @attr [Api::Sponsor]     sponsor
# @attr [SiteType]         site
# @attr [String]           subscriptionType
# @attr [String]           webSite
#
# @see https://apidocs.bookshare.org/reference/index.html#_organization
#
# NOTE: This duplicates:
# @see Api::Organization
#
# noinspection DuplicatedCode
class ApiOrganization < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_one   :address,          Api::Address
    attribute :hasOrgAgreement,  Boolean
    has_many  :links,            Api::Link
    attribute :organizationId,   String
    attribute :organizationName, String
    attribute :organizationType, String
    attribute :phoneNumber,      String
    has_one   :sponsor,          Api::Sponsor
    attribute :site,             SiteType
    attribute :subscriptionType, String
    attribute :webSite,          String
  end

end

__loading_end(__FILE__)
