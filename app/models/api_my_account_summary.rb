# app/models/api_my_account_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/address'
require_relative 'api/link'
require_relative 'api/name'
require_relative 'api/student_status'
require_relative 'api/common/name_methods'

# ApiMyAccountSummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_myaccount_summary
#
# == Implementation Notes
# Similar to ApiUserAccount, but without the following fields:
#   :deleted
#   :emailAddress
#   :language
#   :locked
#   :roles
#   :site
#
class ApiMyAccountSummary < Api::Message

  schema do
    has_one   :address,                 Api::Address
    attribute :canDownload,             Boolean
    attribute :dateOfBirth,             String # TODO: ???
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

  include Api::Common::NameMethods

end

__loading_end(__FILE__)
