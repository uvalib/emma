# app/records/bs/message/user_signed_agreement_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserSignedAgreementList
#
# @attr [Array<AllowsType>]                      allows
# @attr [Array<Bs::Record::Link>]                links
# @attr [Array<Bs::Record::UserSignedAgreement>] signedAgreements
#
# @see https://apidocs.bookshare.org/membership/index.html#_user_signed_agreement_list
#
class Bs::Message::UserSignedAgreementList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many :allows,           AllowsType
    has_many :links,            Bs::Record::Link
    has_many :signedAgreements, Bs::Record::UserSignedAgreement
  end

end

__loading_end(__FILE__)
