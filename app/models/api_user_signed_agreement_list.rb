# app/models/api_user_signed_agreement_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/link_methods'
require_relative 'api/user_signed_agreement'

# ApiUserSignedAgreementList
#
# @attr [Array<AllowsType>]               allows
# @attr [Array<Api::Link>]                links
# @attr [Array<Api::UserSignedAgreement>] signedAgreements
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_signed_agreement_list
#
class ApiUserSignedAgreementList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many :allows,           AllowsType
    has_many :links,            Api::Link
    has_many :signedAgreements, Api::UserSignedAgreement
  end

end

__loading_end(__FILE__)
