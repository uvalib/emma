# app/records/bs/message/my_account_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::MyAccountSummary
#
# @attr [Bs::Record::Address]       address
# @attr [Boolean]                   canDownload
# @attr [String]                    dateOfBirth
# @attr [Bs::Record::Name]          guardian
# @attr [Boolean]                   hasAgreement
# @attr [Array<Bs::Record::Link>]   links
# @attr [Bs::Record::Name]          name
# @attr [String]                    phoneNumber
# @attr [ProofOfDisabilityStatus]   proofOfDisabilityStatus
# @attr [Bs::Record::StudentStatus] studentStatus
# @attr [SubscriptionStatus]        subscriptionStatus
# @attr [String]                    username
#
# @see https://apidocs.bookshare.org/reference/index.html#_myaccount_summary
#
# == Implementation Notes
# Similar to Bs::Message::UserAccount, but without the following fields:
#   :allowAdultContent
#   :deleted
#   :emailAddress
#   :language
#   :locked
#   :roles
#   :site
#
class Bs::Message::MyAccountSummary < Bs::Api::Message

  include Bs::Shared::AccountMethods
  include Bs::Shared::LinkMethods

  schema do
    has_one   :address,                 Bs::Record::Address
    attribute :canDownload,             Boolean
    attribute :dateOfBirth,             String
    has_one   :guardian,                Bs::Record::Name
    attribute :hasAgreement,            Boolean
    has_many  :links,                   Bs::Record::Link
    has_one   :name,                    Bs::Record::Name
    attribute :phoneNumber,             String
    attribute :proofOfDisabilityStatus, ProofOfDisabilityStatus
    has_one   :studentStatus,           Bs::Record::StudentStatus
    attribute :subscriptionStatus,      SubscriptionStatus
    attribute :username,                String
  end

end

__loading_end(__FILE__)