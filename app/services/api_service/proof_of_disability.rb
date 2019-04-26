# app/services/api_service/proof_of_disability.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  module ProofOfDisability

    include Common

    # @type [Hash{Symbol=>String}]
    POD_SEND_MESSAGE = {

      # TODO: e.g.:
      no_items:      'There were no items to request',
      failed:        'Unable to request items right now',

    }.reverse_merge(API_SEND_MESSAGE).freeze

    # @type [Hash{Symbol=>(String,Regexp,nil)}]
    POD_SEND_RESPONSE = {

      # TODO: e.g.:
      no_items:       'no items',
      failed:         nil

    }.reverse_merge(API_SEND_RESPONSE).freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # get_user_pod
    #
    # @param [String]    username
    #
    # @return [ApiUserPodList]
    #
    def get_user_pod(username:)
      api(:post, 'accounts', username, 'pod')
      data = response&.body&.presence
      ApiUserPodList.new(data, error: @exception)
    end

    # create_user_pod
    #
    # @param [String]    username
    # @param [Hash, nil] opt
    #
    # @option opt [DisabilityType]          :disabilityType   *REQUIRED*
    # @option opt [ProofOfDisabilitySource] :proofSource      *REQUIRED*
    #
    # @return [ApiUserPodList]
    #
    def create_user_pod(username:, **opt)
      %i[disabilityType proofSource].each do |key|
        raise RuntimeError, "#{__method__} missing #{key}" if opt[key].blank?
      end
      api(:post, 'accounts', username, 'pod', opt)
      data = response&.body&.presence
      ApiUserPodList.new(data, error: @exception)
    end

    # update_user_pod
    #
    # @param [String]         username
    # @param [DisabilityType] disabilityType
    # @param [Hash, nil]      opt
    #
    # @option opt [ProofOfDisabilitySource] :proofSource      *REQUIRED*
    #
    # @return [ApiUserPodList]
    #
    def update_user_pod(username:, disabilityType:, **opt)
      %i[proofSource].each do |key|
        raise RuntimeError, "#{__method__} missing #{key}" if opt[key].blank?
      end
      api(:put, 'accounts', username, 'pod', disabilityType, opt)
      data = response&.body&.presence
      ApiUserPodList.new(data, error: @exception)
    end

    # remove_user_pod
    #
    # @param [String]         username
    # @param [DisabilityType] disabilityType
    #
    # @return [ApiUserPodList]
    #
    def remove_user_pod(username:, disabilityType:)
      api(:delete, 'accounts', username, 'pod', disabilityType)
      data = response&.body&.presence
      ApiUserPodList.new(data, error: @exception)
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
      response_table = POD_SEND_RESPONSE
      message_table  = POD_SEND_MESSAGE
      message = request_error_message(method, response_table, message_table)
      raise Api::AccountError, message
    end

  end

end

__loading_end(__FILE__)
