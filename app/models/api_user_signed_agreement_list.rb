# app/models/api_user_signed_agreement_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/link'
require 'api/user_signed_agreement'

# ApiUserSignedAgreementList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_signed_agreement_list
#
class ApiUserSignedAgreementList < Api::Message

  schema do
    has_many :allows,           String
    has_many :links,            Link
    has_many :signedAgreements, UserSignedAgreement
  end

end

__loading_end(__FILE__)
