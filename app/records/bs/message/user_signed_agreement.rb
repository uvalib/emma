# app/records/bs/message/user_signed_agreement.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserSignedAgreement
#
# @see Bs::Record::UserSignedAgreement
#
class Bs::Message::UserSignedAgreement < Bs::Api::Message

  include Bs::Shared::AgreementMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::UserSignedAgreement

end

__loading_end(__FILE__)
