# app/services/api_service/agreement.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  # ApiService::Agreement
  #
  # noinspection RubyParameterNamingConvention
  module Agreement

    include Common

    # =========================================================================
    # :section:
    # =========================================================================

    public

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

    # == GET /v2/accounts/:username/agreements
    # Get the list of signed agreements for an existing user.
    #
    # @param [User, String, nil] user       Default: @user
    #
    # @return [ApiUserSignedAgreementList]
    #
    def get_user_agreements(user: @user)
      username = name_of(user)
      api(:post, 'accounts', username, 'agreements')
      ApiUserSignedAgreementList.new(response, error: exception)
    end

    # == POST /v2/accounts/:username/agreements
    # Create a new signed agreement record for an existing user
    #
    # @param [User, String, nil] user       Default: @user
    # @param [Hash, nil]         opt
    #
    # @option opt [AgreementType] :agreementType          *REQUIRED*
    # @option opt [String]        :dateSigned             *REQUIRED*
    # @option opt [String]        :printName              *REQUIRED*
    # @option opt [String]        :signedByLegalGuardian
    #
    # @return [ApiUserSignedAgreement]
    #
    def create_user_agreement(user: @user, **opt)
      validate_parameters(__method__, opt)
      username = name_of(user)
      api(:post, 'accounts', username, 'agreements', opt)
      ApiUserSignedAgreement.new(response, error: exception)
    end

    # == POST /v2/accounts/:username/agreements/:agreementId/expired
    # Expire a signed agreement.
    #
    # @param [User, String, nil] user         Default: @user
    # @param [String]            agreementId
    #
    # @return [ApiUserSignedAgreement]
    #
    def remove_user_agreement(user: @user, agreementId:)
      username = name_of(user)
      api(:post, 'accounts', username, 'agreements', agreementId, 'expired')
      ApiUserSignedAgreement.new(response, error: exception)
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

  end unless defined?(Agreement)

end

__loading_end(__FILE__)
