# app/services/api_service/agreement.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  module Agreement

    include Common

    # @type [Hash{Symbol=>String}]
    AGREEMENT_SEND_MESSAGE = {

      # TODO: e.g.:
      no_items:      'There were no items to request',
      failed:        'Unable to request items right now',

    }.reverse_merge(API_SEND_MESSAGE).freeze

    # @type [Hash{Symbol=>(String,Regexp,nil)}]
    AGREEMENT_SEND_RESPONSE = {

      # TODO: e.g.:
      no_items:       'no items',
      failed:         nil

    }.reverse_merge(API_SEND_RESPONSE).freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # get_user_agreements
    #
    # @param [User, String] user
    #
    # @return [ApiUserSignedAgreementList]
    #
    def get_user_agreements(user:)
      username = get_username(user)
      api(:post, 'accounts', username, 'agreements')
      data = response&.body&.presence
      ApiUserSignedAgreementList.new(data, error: @exception)
    end

    # create_user_agreement
    #
    # @param [User, String] user
    # @param [Hash, nil]    opt
    #
    # @option opt [AgreementType] :agreementType          *REQUIRED*
    # @option opt [String]        :dateSigned             *REQUIRED*
    # @option opt [String]        :printName              *REQUIRED*
    # @option opt [String]        :signedByLegalGuardian
    #
    # @return [ApiUserSignedAgreement]
    #
    def create_user_agreement(user:, **opt)
      validate_parameters(__method__, opt)
      username = get_username(user)
      api(:post, 'accounts', username, 'agreements', opt)
      data = response&.body&.presence
      ApiUserSignedAgreement.new(data, error: @exception)
    end

    # remove_user_agreement
    #
    # @param [User, String] user
    # @param [String]       agreementId
    #
    # @return [ApiUserSignedAgreement]
    #
    def remove_user_agreement(user:, agreementId:)
      username = get_username(user)
      api(:post, 'accounts', username, 'agreements', agreementId, 'expired')
      data = response&.body&.presence
      ApiUserSignedAgreement.new(data, error: @exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # raise_exception
    #
    # @param [Symbol, String] method  For log messages.
    #
    # This method overrides:
    # @see ApiService::Common#raise_exception
    #
    def raise_exception(method)
      response_table = AGREEMENT_SEND_RESPONSE
      message_table  = AGREEMENT_SEND_MESSAGE
      message = request_error_message(method, response_table, message_table)
      raise Api::AccountError, message
    end

  end

end

__loading_end(__FILE__)
