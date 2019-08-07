# app/models/api/user_account.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/account_methods'
require_relative 'common/link_methods'
require_relative 'address'
require_relative 'name'

# Api::UserAccount
#
# @attr [Api::Address]            address
# @attr [Boolean]                 allowAdultContent
# @attr [Boolean]                 canDownload
# @attr [String]                  dateOfBirth
# @attr [Boolean]                 deleted
# @attr [String]                  emailAddress
# @attr [Api::Name]               guardian
# @attr [Boolean]                 hasAgreement
# @attr [String]                  language
# @attr [Array<Api::Link>]        links
# @attr [Boolean]                 locked
# @attr [Api::Name]               name
# @attr [String]                  phoneNumber
# @attr [ProofOfDisabilityStatus] proofOfDisabilityStatus
# @attr [Array<String>]           roles
# @attr [SiteType]                site
# @attr [SubscriptionStatus]      subscriptionStatus
# @attr [String]                  userAccountId
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_account
#
# NOTE: This duplicates:
# @see ApiUserAccount
#
# noinspection DuplicatedCode
class Api::UserAccount < Api::Record::Base

  include Api::Common::AccountMethods
  include Api::Common::LinkMethods

  schema do
    has_one   :address,                 Api::Address
    attribute :allowAdultContent,       Boolean
    attribute :canDownload,             Boolean
    attribute :dateOfBirth,             String
    attribute :deleted,                 Boolean
    attribute :emailAddress,            String
    has_one   :guardian,                Api::Name
    attribute :hasAgreement,            Boolean
    attribute :language,                String
    has_many  :links,                   Api::Link
    attribute :locked,                  Boolean
    has_one   :name,                    Api::Name
    attribute :phoneNumber,             String
    attribute :proofOfDisabilityStatus, ProofOfDisabilityStatus
    has_many  :roles,                   String
    attribute :site,                    SiteType
    attribute :subscriptionStatus,      SubscriptionStatus
    attribute :userAccountId,           String
  end

end

__loading_end(__FILE__)
