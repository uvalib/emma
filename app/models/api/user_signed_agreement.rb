# app/models/api/user_signed_agreement.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::UserSignedAgreement
#
# @attr [String]        agreementId
# @attr [AgreementType] agreementType
# @attr [String]        dateExpired
# @attr [String]        dateSigned
# @attr [String]        printName
# @attr [String]        recordingUser
# @attr [Boolean]       signedByLegalGuardian
# @attr [String]        username
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_signed_agreement
#
# NOTE: This duplicates:
# @see ApiUserSignedAgreement
#
# noinspection DuplicatedCode
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
