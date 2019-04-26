# app/models/api/user_account.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/address'
require 'api/name'
require 'api/link'

# Api::UserAccount
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_account
#
class Api::UserAccount < Api::Record::Base

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
