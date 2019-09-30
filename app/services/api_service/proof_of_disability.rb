# app/services/api_service/proof_of_disability.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::ProofOfDisability
#
# noinspection RubyParameterNamingConvention
module ApiService::ProofOfDisability

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/pod
  # Get the list of disabilities for an existing user.
  #
  # @param [User, String, nil] user   Default: @user
  #
  # @return [ApiUserPodList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-membership-pods
  #
  def get_user_pod(user: @user)
    username = name_of(user)
    api(:post, 'accounts', username, 'pod')
    ApiUserPodList.new(response, error: exception)
  end

  # == POST /v2/accounts/{userIdentifier}/pod
  # Create a new record of a disability for an existing user.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    API URL parameters
  #
  # @option opt [DisabilityType]          :disabilityType   *REQUIRED*
  # @option opt [ProofOfDisabilitySource] :proofSource      *REQUIRED*
  #
  # @return [ApiUserPodList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-membership-pod
  #
  def create_user_pod(user: @user, **opt)
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:post, 'accounts', username, 'pod', **opt)
    ApiUserPodList.new(response, error: exception)
  end

  # == PUT /v2/accounts/{userIdentifier}/pod/{disabilityType}
  # Update the proof source for a disability for an existing user.
  #
  # @param [User, String, nil] user             Default: @user
  # @param [DisabilityType]    disabilityType
  # @param [Hash]              opt              API URL parameters
  #
  # @option opt [ProofOfDisabilitySource] :proofSource      *REQUIRED*
  #
  # @return [ApiUserPodList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_update-membership-pod
  #
  def update_user_pod(user: @user, disabilityType:, **opt)
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:put, 'accounts', username, 'pod', disabilityType, **opt)
    ApiUserPodList.new(response, error: exception)
  end

  # == DELETE /v2/accounts/{userIdentifier}/pod/{disabilityType}
  # Remove a proof of disability for an existing user.
  #
  # @param [User, String, nil] user             Default: @user
  # @param [DisabilityType]    disabilityType
  #
  # @return [ApiUserPodList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_delete-membership-pod
  #
  def remove_user_pod(user: @user, disabilityType:)
    username = name_of(user)
    api(:delete, 'accounts', username, 'pod', disabilityType)
    ApiUserPodList.new(response, error: exception)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # raise_exception
  #
  # @param [Symbol, String] method    For log messages.
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

__loading_end(__FILE__)
