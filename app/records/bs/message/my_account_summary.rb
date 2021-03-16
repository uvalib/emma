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
# @attr [BsProofOfDisabilityStatus] proofOfDisabilityStatus
# @attr [Bs::Record::StudentStatus] studentStatus
# @attr [BsSubscriptionStatus]      subscriptionStatus
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
    has_one   :canDownload,             Boolean
    has_one   :dateOfBirth
    has_one   :guardian,                Bs::Record::Name
    has_one   :hasAgreement,            Boolean
    has_many  :links,                   Bs::Record::Link
    has_one   :name,                    Bs::Record::Name
    has_one   :phoneNumber
    has_one   :proofOfDisabilityStatus, BsProofOfDisabilityStatus
    has_one   :studentStatus,           Bs::Record::StudentStatus
    has_one   :subscriptionStatus,      BsSubscriptionStatus
    has_one   :username
  end

end

__loading_end(__FILE__)
