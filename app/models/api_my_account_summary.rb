# app/models/api_my_account_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiMyAccountSummary
#
# @attr [Api::Address]            address
# @attr [Boolean]                 canDownload
# @attr [String]                  dateOfBirth
# @attr [Api::Name]               guardian
# @attr [Boolean]                 hasAgreement
# @attr [Array<Api::Link>]        links
# @attr [Api::Name]               name
# @attr [String]                  phoneNumber
# @attr [ProofOfDisabilityStatus] proofOfDisabilityStatus
# @attr [Api::StudentStatus]      studentStatus
# @attr [SubscriptionStatus]      subscriptionStatus
# @attr [String]                  username
#
# @see https://apidocs.bookshare.org/reference/index.html#_myaccount_summary
#
# == Implementation Notes
# Similar to ApiUserAccount, but without the following fields:
#   :allowAdultContent
#   :deleted
#   :emailAddress
#   :language
#   :locked
#   :roles
#   :site
#
class ApiMyAccountSummary < Api::Message

  include Api::Common::AccountMethods
  include Api::Common::LinkMethods

  schema do
    has_one   :address,                 Api::Address
    attribute :canDownload,             Boolean
    attribute :dateOfBirth,             String
    has_one   :guardian,                Api::Name
    attribute :hasAgreement,            Boolean
    has_many  :links,                   Api::Link
    has_one   :name,                    Api::Name
    attribute :phoneNumber,             String
    attribute :proofOfDisabilityStatus, ProofOfDisabilityStatus
    has_one   :studentStatus,           Api::StudentStatus
    attribute :subscriptionStatus,      SubscriptionStatus
    attribute :username,                String
  end

end

__loading_end(__FILE__)
