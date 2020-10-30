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
#--
# noinspection DuplicatedCode
#++
class Bs::Record::UserAccount < Bs::Api::Record

  include Bs::Shared::AccountMethods
  include Bs::Shared::LinkMethods

  schema do
    has_one   :address,                 Bs::Record::Address
    has_one   :allowAdultContent,       Boolean
    has_one   :canDownload,             Boolean
    has_one   :dateOfBirth
    has_one   :deleted,                 Boolean
    has_one   :emailAddress
    has_one   :guardian,                Bs::Record::Name
    has_one   :hasAgreement,            Boolean
    has_one   :language
    has_many  :links,                   Bs::Record::Link
    has_one   :locked,                  Boolean
    has_one   :name,                    Bs::Record::Name
    has_one   :phoneNumber
    has_one   :proofOfDisabilityStatus, ProofOfDisabilityStatus
    has_many  :roles
    has_one   :site,                    SiteType
    has_one   :subscriptionStatus,      SubscriptionStatus
    has_one   :userAccountId
  end

end

__loading_end(__FILE__)
