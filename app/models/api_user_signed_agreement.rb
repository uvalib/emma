# app/models/api_user_signed_agreement.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/user_signed_agreement'

# ApiUserSignedAgreement
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_signed_agreement
#
# NOTE: This duplicates:
# @see Api::UserSignedAgreement
#
# noinspection DuplicatedCode
class ApiUserSignedAgreement < Api::Message

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

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Convert object to string.
  #
  # @return [String]
  #
  def to_s
    label
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the item.
  #
  # @return [String]
  #
  def label
    identifier
  end

  # Return the unique identifier for the represented item.
  #
  # @return [String]
  #
  def identifier
    agreementId.to_s
  end

end

__loading_end(__FILE__)
