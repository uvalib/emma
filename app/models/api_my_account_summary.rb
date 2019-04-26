# app/models/api_my_account_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/address'
require 'api/name'
require 'api/link'
require 'api/student_status'

# ApiMyAccountSummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_myaccount_summary
#
class ApiMyAccountSummary < Api::Message

  schema do
    attribute :address,                 Address
    attribute :canDownload,             Boolean
    attribute :dateOfBirth,             String # TODO: ???
    attribute :guardian,                Name
    attribute :hasAgreement,            Boolean
    has_many  :links,                   Link
    attribute :name,                    Name
    attribute :phoneNumber,             String
    attribute :proofOfDisabilityStatus, ProofOfDisabilityStatus
    attribute :studentStatus,           StudentStatus
    attribute :subscriptionStatus,      SubscriptionStatus
    attribute :username,                String
  end

end

__loading_end(__FILE__)
