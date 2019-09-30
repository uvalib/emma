# app/services/api_service/organization.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::Organization
#
module ApiService::Organization

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>String}]
  ORGANIZATION_SEND_MESSAGE = {

    # TODO: e.g.:
    no_items:      'There were no items to request',
    failed:        'Unable to request items right now',

  }.reverse_merge(API_SEND_MESSAGE).freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  ORGANIZATION_SEND_RESPONSE = {

    # TODO: e.g.:
    no_items:       'no items',
    failed:         nil

  }.reverse_merge(API_SEND_RESPONSE).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myOrganization/members
  # Get a list of members of the current (sponsor) user's organization.
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [String]          :start
  # @option opt [Integer]         :limit        Default: 10
  # @option opt [MemberSortOrder] :sortOrder    Default: 'lastName'
  # @option opt [Direction]       :direction    Default: 'asc'
  #
  # @return [ApiUserAccountList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-myorganization-members
  #
  def get_my_organization_members(**opt)
    validate_parameters(__method__, opt)
    api(:get, 'myOrganization', 'members', **opt)
    ApiUserAccountList.new(response, error: exception)
  end

  # == GET /v2/myOrganization/members/{userIdentifier}
  # Get a member of the current (sponsor) user's organization.
  #
  # @param [String] username
  #
  # @return [ApiUserAccount]
  #
  # NOTE: This is not a real Bookshare API call.
  #
  def get_my_organization_member(username:)
    all = get_my_organization_members(limit: :max)
    om  = all.userAccounts.find { |list| list.identifier == username }
    ApiUserAccount.new(om)
  end

  # == POST /v2/myOrganization/members
  # Create a new user account for the current user's organization.
  #
  # @param [Hash]   opt               API URL parameters
  #
  # @option opt [String]                  :firstName        *REQUIRED*
  # @option opt [String]                  :lastName         *REQUIRED*
  # @option opt [String]                  :dateOfBirth      *REQUIRED*
  # @option opt [String]                  :grade            *REQUIRED*
  # @option opt [String]                  :username
  # @option opt [String]                  :password
  # @option opt [DisabilityType]          :disabilityType   *REQUIRED*
  # @option opt [ProofOfDisabilitySource] :proofSource      *REQUIRED*
  # @option opt [DisabilityPlan, Array<DisabilityPlan>] :disabilityPlan
  #
  # @return [ApiUserAccount]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-my-organizationmember
  #
  def add_organization_member(**opt)
    validate_parameters(__method__, opt)
    api(:post, 'myOrganization', 'members', **opt)
    ApiUserAccount.new(response, error: exception)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/organizations/{organizationId}
  # Get details about the specified organization.
  #
  # @param [String] organization
  #
  # @return [ApiOrganization]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-organization
  #
  def get_organization(organization:)
    api(:get, 'organizations', organization)
    ApiOrganization.new(response, error: exception)
  end

  # == POST /v2/organizations
  # Create a new organization.
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [String]   :organizationName    *REQUIRED*
  # @option opt [String]   :address1            *REQUIRED*
  # @option opt [String]   :address2
  # @option opt [String]   :city                *REQUIRED*
  # @option opt [String]   :state
  # @option opt [String]   :country             *REQUIRED*
  # @option opt [String]   :postalCode          *REQUIRED*
  # @option opt [String]   :website
  # @option opt [String]   :organizationType    *REQUIRED*
  # @option opt [SiteType] :site
  # @option opt [String]   :contactFirstName    *REQUIRED*
  # @option opt [String]   :contactLastName     *REQUIRED*
  # @option opt [String]   :contactPhoneNumber  *REQUIRED*
  # @option opt [String]   :contactTitle        *REQUIRED*
  # @option opt [String]   :contactEmailAddress *REQUIRED*
  #
  # @return [ApiOrganization]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-organization
  #
  def create_organization(**opt)
    validate_parameters(__method__, opt)
    api(:post, 'organizations', **opt)
    ApiOrganization.new(response, error: exception)
  end

  # == POST /v2/organizations/{organizationId}/members
  # Create a new organization user account.
  #
  # @param [String] organization
  # @param [Hash]   opt               API URL parameters
  #
  # @option opt [String]                  :firstName        *REQUIRED*
  # @option opt [String]                  :lastName         *REQUIRED*
  # @option opt [String]                  :dateOfBirth      *REQUIRED*
  # @option opt [String]                  :grade            *REQUIRED*
  # @option opt [String]                  :username
  # @option opt [String]                  :password
  # @option opt [DisabilityType]          :disabilityType   *REQUIRED*
  # @option opt [ProofOfDisabilitySource] :proofSource      *REQUIRED*
  # @option opt [DisabilityPlan, Array<DisabilityPlan>] :disabilityPlan
  #
  # @return [ApiUserAccount]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-organization
  #
  def create_organization_member(organization:, **opt)
    validate_parameters(__method__, opt)
    api(:post, 'organizations', organization, 'members', **opt)
    ApiUserAccount.new(response, error: exception)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/organizationTypes
  # Get the list of organization types relevant to the current user.
  #
  # @return [ApiOrganizationTypeList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-organization-types
  #
  def get_organization_types(*)
    api(:get, 'organizationTypes')
    ApiOrganizationTypeList.new(response, error: exception)
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
    response_table = ORGANIZATION_SEND_RESPONSE
    message_table  = ORGANIZATION_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::OrganizationError, message
  end

end

__loading_end(__FILE__)
