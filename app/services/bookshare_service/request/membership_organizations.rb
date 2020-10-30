# app/services/bookshare_service/request/membership_organizations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::MembershipOrganizations
#
# == Usage Notes
#
# === From API section 2.11 (Membership Assistant - Organizations):
# Membership Assistant users are able to view, create and update organization
# accounts.
#
module BookshareService::Request::MembershipOrganizations

  include BookshareService::Common

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
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Bs::Message::Organization]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-organization
  #
  def get_organization(organization:, **opt)
    api(:get, 'organizations', organization, **opt)
    Bs::Message::Organization.new(response, error: exception)
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
  # @param [Hash] opt                 Passed to #api.
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
  # @return [Bs::Message::Organization]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-organization
  #
  def create_organization(**opt)
    opt = get_parameters(__method__, **opt)
    api(:post, 'organizations', **opt)
    Bs::Message::Organization.new(response, error: exception)
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
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [String]          :start
  # @option opt [Integer]         :limit      Default: 10
  # @option opt [MemberSortOrder] :sortOrder  Default: 'lastName'
  # @option opt [Direction]       :direction  Default: 'asc'
  #
  # @return [Bs::Message::UserAccountList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-organization-members
  #
  def get_organization_members(organization:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'organizations', organization, 'members', **opt)
    Bs::Message::UserAccountList.new(response, error: exception)
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
  # @param [Hash]   opt               Passed to #api.
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
  # @return [Bs::Message::UserAccount]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-organizationmember
  #
  def add_organization_member(organization:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:post, 'organizations', organization, 'members', **opt)
    Bs::Message::UserAccount.new(response, error: exception)
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
  # @param [Hash] opt                 Passed to #api.
  #
  # @return [Bs::Message::OrganizationTypeList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-organization-types
  #
  def get_organization_types(**opt)
    api(:get, 'organizationTypes', **opt)
    Bs::Message::OrganizationTypeList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        reference_id: '_get-organization-types'
      }
    end

end

__loading_end(__FILE__)
