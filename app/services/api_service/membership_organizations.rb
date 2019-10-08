# app/services/api_service/membership_organizations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::MembershipOrganizations
#
# == Usage Notes
#
# === From API section 2.11 (Membership Assistant - Organizations):
# Membership Assistant users are able to view, create and update organization accounts.
#
module ApiService::MembershipOrganizations

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>String}]
  MEMBERSHIP_ORGANIZATIONS_SEND_MESSAGE = {

    # TODO: e.g.:
    no_items:      'There were no items to request',
    failed:        'Unable to request items right now',

  }.reverse_merge(API_SEND_MESSAGE).freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  MEMBERSHIP_ORGANIZATIONS_SEND_RESPONSE = {

    # TODO: e.g.:
    no_items:       'no items',
    failed:         nil

  }.reverse_merge(API_SEND_RESPONSE).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/organizations/{organizationId}
  #
  # == 2.11.2. Get organization information
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
    .tap do |method|
      add_api method => {
        alias: {
          organization:   :organizationId,
        },
        required: {
          organizationId: String,
        },
        reference_id:     '_get-organization'
      }
    end

  # == POST /v2/organizations
  #
  # == 2.11.1. Create an organization
  # Create a new organization.
  #
  # @param [Hash] opt                 Optional API URL parameters.
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
    opt = get_parameters(__method__, **opt)
    api(:post, 'organizations', **opt)
    ApiOrganization.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          organizationName:    String,
          address1:            String,
          city:                String,
          country:             String,
          postalCode:          String,
          organizationType:    String,
          contactFirstName:    String,
          contactLastName:     String,
          contactPhoneNumber:  String,
          contactTitle:        String,
          contactEmailAddress: String,
        },
        optional: {
          address2:            String,
          state:               String,
          website:             String,
          site:                SiteType,
        },
        reference_id:          '_create-organization'
      }
    end

  # == GET /v2/organizations/{organizationId}/members
  #
  # == 2.11.3. Get a list of members in an organization
  # Get a list of members of the given organization.
  #
  # @param [String] organization
  # @param [Hash]   opt               Optional API URL parameters.
  #
  # @option opt [String]          :start
  # @option opt [Integer]         :limit      Default: 10
  # @option opt [MemberSortOrder] :sortOrder  Default: 'lastName'
  # @option opt [Direction]       :direction  Default: 'asc'
  #
  # @return [ApiUserAccountList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-organization-members
  #
  def get_organization_members(organization:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'organizations', organization, 'members', **opt)
    ApiUserAccountList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          organization:   :organizationId,
        },
        required: {
          organizationId: String,
        },
        optional: {
          start:          String,
          limit:          Integer,
          sortOrder:      MemberSortOrder,
          direction:      Direction,
        },
        reference_id:     '_get-organization-members'
      }
    end

  # == POST /v2/organizations/{organizationId}/members
  #
  # == 2.11.4. Create a user for an organization
  # Create a new organization user account.
  #
  # @param [String] organization
  # @param [Hash]   opt               Optional API URL parameters.
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
  # @see https://apidocs.bookshare.org/reference/index.html#_create-organizationmember
  #
  def add_organization_member(organization:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:post, 'organizations', organization, 'members', **opt)
    ApiUserAccount.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          organization:   :organizationId,
        },
        required: {
          organizationId: String,
          firstName:      String,
          lastName:       String,
          dateOfBirth:    String,
          grade:          String,
          disabilityType: DisabilityType,
          proofSource:    ProofOfDisabilitySource,
        },
        optional: {
          username:       String,
          password:       String,
          disabilityPlan: DisabilityPlan,
        },
        multi:            %i[disabilityPlan],
        reference_id:     '_create-organizationmember'
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/organizationTypes
  #
  # == 2.11.5. Get organization types
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
    .tap do |method|
      add_api method => {
        reference_id: '_get-organization-types'
      }
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
    response_table = MEMBERSHIP_ORGANIZATIONS_SEND_RESPONSE
    message_table  = MEMBERSHIP_ORGANIZATIONS_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::OrganizationError, message
  end

end

__loading_end(__FILE__)
