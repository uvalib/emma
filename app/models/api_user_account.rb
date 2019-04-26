# app/models/api_user_account.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/user_account'

# ApiUserAccount
#
# NOTE: This duplicates Api::UserAccount
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_account
#
class ApiUserAccount < Api::Message

  schema do
    attribute :address,                 Address
    attribute :allowAdultContent,       Boolean
    attribute :canDownload,             Boolean
    attribute :dateOfBirth,             String
    attribute :deleted,                 Boolean
    attribute :emailAddress,            String
    attribute :guardian,                Name
    attribute :hasAgreement,            Boolean
    attribute :language,                String
    has_many  :links,                   Link
    attribute :locked,                  Boolean
    attribute :name,                    Name
    attribute :phoneNumber,             String
    attribute :proofOfDisabilityStatus, ProofOfDisabilityStatus
    has_many  :roles,                   String
    attribute :site,                    SiteType
    attribute :subscriptionStatus,      SubscriptionStatus
  end

end

__loading_end(__FILE__)
