# app/models/api/user_signed_agreement.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::UserSignedAgreement
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_signed_agreement
#
class Api::UserSignedAgreement < Api::Record::Base

  schema do
    attribute :agreementId,           String
    attribute :agreementType,         AgreementType
    attribute :dateExpired,           String
    attribute :dateSigned,            String
    attribute :printName,             String
    attribute :recordingUser,         String
    attribute :signedByLegalGuardian, Boolean
    attribute :username,              String
  end

end

__loading_end(__FILE__)
