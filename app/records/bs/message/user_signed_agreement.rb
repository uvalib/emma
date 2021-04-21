# app/records/bs/message/user_signed_agreement.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserSignedAgreement
#
# @attr [String]          agreementId
# @attr [BsAgreementType] agreementType
# @attr [String]          dateExpired
# @attr [String]          dateSigned
# @attr [String]          printName
# @attr [String]          recordingUser
# @attr [Boolean]         signedByLegalGuardian
# @attr [String]          username
#
# @see https://apidocs.bookshare.org/membership/index.html#_user_signed_agreement
#
# @see Bs::Record::UserSignedAgreement (duplicate schema)
#
class Bs::Message::UserSignedAgreement < Bs::Api::Message

  include Bs::Shared::AgreementMethods

  schema do
    has_one   :agreementId
    has_one   :agreementType,         BsAgreementType
    has_one   :dateExpired
    has_one   :dateSigned
    has_one   :printName
    has_one   :recordingUser
    has_one   :signedByLegalGuardian, Boolean
    has_one   :username
  end

end

__loading_end(__FILE__)
