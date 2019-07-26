# app/models/api/user_account.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'address'
require_relative 'link'
require_relative 'name'
require_relative 'common/account_methods'
require_relative 'common/link_methods'

# Api::UserAccount
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_account
#
# NOTE: This duplicates:
# @see ApiUserAccount
#
class Api::UserAccount < Api::Record::Base

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
  end

  include Api::Common::AccountMethods
  include Api::Common::LinkMethods

end

__loading_end(__FILE__)
