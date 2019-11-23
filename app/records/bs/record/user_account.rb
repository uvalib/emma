# app/records/bs/record/user_account.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::UserAccount
#
# @attr [Bs::Record::Address]     address
# @attr [Boolean]                 allowAdultContent
# @attr [Boolean]                 canDownload
# @attr [String]                  dateOfBirth
# @attr [Boolean]                 deleted
# @attr [String]                  emailAddress
# @attr [Bs::Record::Name]        guardian
# @attr [Boolean]                 hasAgreement
# @attr [String]                  language
# @attr [Array<Bs::Record::Link>] links
# @attr [Boolean]                 locked
# @attr [Bs::Record::Name]        name
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
# @see Bs::Message::UserAccount
#
# noinspection DuplicatedCode
class Bs::Record::UserAccount < Bs::Api::Record

  include Bs::Shared::AccountMethods
  include Bs::Shared::LinkMethods

  schema do
    has_one   :address,                 Bs::Record::Address
    attribute :allowAdultContent,       Boolean
    attribute :canDownload,             Boolean
    attribute :dateOfBirth,             String
    attribute :deleted,                 Boolean
    attribute :emailAddress,            String
    has_one   :guardian,                Bs::Record::Name
    attribute :hasAgreement,            Boolean
    attribute :language,                String
    has_many  :links,                   Bs::Record::Link
    attribute :locked,                  Boolean
    has_one   :name,                    Bs::Record::Name
    attribute :phoneNumber,             String
    attribute :proofOfDisabilityStatus, ProofOfDisabilityStatus
    has_many  :roles,                   String
    attribute :site,                    SiteType
    attribute :subscriptionStatus,      SubscriptionStatus
    attribute :userAccountId,           String
  end

end

__loading_end(__FILE__)
