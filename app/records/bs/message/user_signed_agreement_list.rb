# app/records/bs/message/user_signed_agreement_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserSignedAgreementList
#
# @attr [Array<BsAllowsType>]                    allows
# @attr [Array<Bs::Record::Link>]                links
# @attr [Array<Bs::Record::UserSignedAgreement>] signedAgreements
#
# @see https://apidocs.bookshare.org/membership/index.html#_user_signed_agreement_list
#
class Bs::Message::UserSignedAgreementList < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::UserSignedAgreement

  schema do
    has_many :allows,           BsAllowsType
    has_many :links,            Bs::Record::Link
    has_many :signedAgreements, LIST_ELEMENT
  end

end

__loading_end(__FILE__)
