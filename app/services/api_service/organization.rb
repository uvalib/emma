# app/services/api_service/organization.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::Organization
#
# == Usage Notes
#
# === From API section 2.7 (Organization):
# An organization represents a collection of users, either sponsors or members.
# These might be schools, libraries or other organizations that work on behalf
# of qualified individuals.  Members of an organization are sometimes
# restricted in what actions they can perform, with sponsors acting on their
# behalf to do things like download titles.  Sponsors have some limited
# administrative abilities in their organizations, to add, update and remove
# individual members.
#
module ApiService::Organization

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myOrganization/members
  #
  # == 2.7.1. Get a list of members of my organization
  # Get a list of members of the current (sponsor) user's organization.
  #
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [String]          :start
  # @option opt [Integer]         :limit      Default: 10
  # @option opt [MemberSortOrder] :sortOrder  Default: 'lastName'
  # @option opt [Direction]       :direction  Default: 'asc'
  #
  # @return [ApiUserAccountList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-myorganization-members
  #
  def get_my_organization_members(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myOrganization', 'members', **opt)
    ApiUserAccountList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          start:      String,
          limit:      Integer,
          sortOrder:  MemberSortOrder,
          direction:  Direction,
        },
        reference_id: '_get-myorganization-members'
      }
    end

  # == GET /v2/myOrganization/members/{userIdentifier}
  # Get a member of the current (sponsor) user's organization.
  #
  # @param [User, String, nil] user
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [ApiUserAccount]
  #
  # NOTE: This is not a real Bookshare API call.
  #
  def get_my_organization_member(user:, **opt)
    username = name_of(user)
    all = get_my_organization_members(limit: :max, **opt)
    om  = all.userAccounts.find { |list| list.identifier == username }
    ApiUserAccount.new(om)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        reference_id:     nil,
      }
    end

  # == POST /v2/myOrganization/members
  #
  # == 2.7.2. Create a user for my organization
  # Create a new user account for the current user's organization.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]                  :firstName      *REQUIRED*
  # @option opt [String]                  :lastName       *REQUIRED*
  # @option opt [String]                  :dateOfBirth    *REQUIRED*
  # @option opt [String]                  :grade          *REQUIRED*
  # @option opt [String]                  :username
  # @option opt [String]                  :password
  # @option opt [DisabilityType]          :disabilityType *REQUIRED*
  # @option opt [ProofOfDisabilitySource] :proofSource    *REQUIRED*
  # @option opt [DisabilityPlan, Array<DisabilityPlan>] :disabilityPlan
  #
  # @return [ApiUserAccount]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-my-organizationmember
  #
  def add_my_organization_member(**opt)
    opt = get_parameters(__method__, **opt)
    api(:post, 'myOrganization', 'members', **opt)
    ApiUserAccount.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
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
        reference_id:     '_create-my-organizationmember'
      }
    end

end

__loading_end(__FILE__)
