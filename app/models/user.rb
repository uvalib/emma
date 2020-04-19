# app/models/user.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for the representation of an EMMA/Bookshare user.
#
# == Implementation Notes
# NOTE: There is still some friction between the concepts of User and Member.
#
# === Documented "types" of "users"
# Section 2.6 of the API documentation mentions "Membership Assistants" and
# "administrators" as being able to access "/v2/accounts" where:
# - A Membership Assistant is allowed to see and manage only those user
#   accounts that are associated with their site.
# - Administrators are allowed access to users across all sites.
#
# @see https://www.bookshare.org/cms/help-center/how-do-i-use-bookshare-web-reader
# This page mentions "Individual Member", "Student Member",
# "Bookshare teacher", and "sponsor".
#
# @see https://www.bookshare.org/cms/help-center/what-kind-account-should-my-students-use
# There are three main types of student Bookshare accounts: Individual
# Memberships, Organizational Memberships, and Linked Accounts.
#
# @see https://www.bookshare.org/cms/help-center/how-do-i-create-individual-membership-my-student
# [A] sponsor can set a limited access username and password to allow a
# member to log in and access books shared on a Reading List. Once the member
# logs in they can select the "Upgrade to an Individual membership" link
# found on the left side of their My Bookshare page to learn how to upgrade
# to a full Individual Membership.  Or a sponsor on the account can [...]
# provide an 'Activation ID' to the student.
#
# @see https://www.bookshare.org/cms/help-center/what-activation-id
# If you were originally registered for Bookshare as an Organizational Member
# (e.g. a student at a school), your Bookshare Sponsor can provide you an
# Activation ID that will link your new Individual Membership to the
# Organization. With this Activation ID your Organization has verified you
# Proof of Disability, and if you are over 18 your account would be
# immediately active. Members who are under 18 will still need to submit an
# Individual Agreement form to complete registration.
#
# === Prototypical users
# Bookshare seems to merge the concepts of "role" and "prototypical user".
# The test accounts that we were given seem to represent four "types" of users,
# although it's not clear whether these are all the "types" that are meant to
# exist.
#
# ==== EMMADSO@bookshare.org
# The home page has button for "Add Students".
#
# In "My Bookshare", this user:
# - has a link for "Members".
# - has a link for "Sponsors".
# - has a link for "My Requests".
#
# This user seems to be typical of current (DSO "sponsor") users that have
# Bookshare accounts.
#
# ==== EmmaVolunteer@bookshare.org
# The home page has links for "Checkout a Book" and "Submit a Book".
#
# In "My Bookshare", this user:
# - has none of the sidebar-links that a DSO "sponsor" has.
# - does not seem to be part of the same org as "EMMADSO@bookshare.org".
#
# This user seems to be typical of current "volunteer" Bookshare users which
# are (often?) unassociated with any DSO.
#
# ==== emmacollection@bookshare.org
# This user's home page says:
# We are so excited to have you help us with the approval queue and introduce
# this new account role.
#
# In "My Bookshare", this user:
# - has a link for "Collection Admin" to catalog.bookshare.org.
# - does not have a link for "Members".
# - does not have a link for "Sponsors".
# - does not have a link for "My Requests".
# - does not seem to have visibility into organization reading lists.
# - does not seem to be part of the same org as "EMMADSO@bookshare.org".
#
# Evidently, this "type" of user is completely new and not fully fleshed-out in
# terms of what it is meant to do.
#
# ==== EmmaMembership@bookshare.org
# This user cannot log in to www.bookshare.org or catalog.bookshare.org and
# appears to be a "type" of user that is completely new.
#
class User < ApplicationRecord

  include Roles

  has_many :members
  has_many :reading_lists

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :rememberable, :omniauthable,
         omniauth_providers: OAUTH2_PROVIDERS

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  rolify

  # ===========================================================================
  # :section: Validations
  # ===========================================================================

  validate on: :create do
    unless uid.match?(/^.+@.+$/)
      errors.add(:base, 'User ID must be a valid email address')
    end
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  after_create :assign_default_role

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Hash, nil] attributes
  #
  def initialize(attributes = nil) # TODO: keep?
    super
    assign_default_role # TODO: remove after tmp test users have been updated
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Display the User instance as the user identifier.
  #
  # @return [String]
  #
  def to_s
    uid.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The user ID is the same as the Bookshare ID, which is the same as the email
  # address.
  #
  # @return [String]
  #
  def uid
    email
  end

  # Indicate whether the user is both an Organizational Member and an
  # Institutional Member.
  #
  # @see Member#linked_account?
  #
  def linked_account?
    as_member = Member.find_by(emailAddress: email)
    as_member.present? && as_member.linked_account?
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # assign_default_role
  #
  # @return [void]
  #
  # == Implementation Notes
  # A new User will be created the first time a new person authenticates via
  # Bookshare -- this may be the place to query the Bookshare API for that
  # user's Bookshare role in order to map it onto EMMA "prototype user".
  #
  def assign_default_role
    return if self.roles.present?
    prototype_user =
      case self.uid
        when 'emmadso@bookshare.org'        then :dso        # NOTE: tmp test user
        when 'emmacollection@bookshare.org' then :collection # NOTE: tmp test user
        when 'emmamembership@bookshare.org' then :membership # NOTE: tmp test user
        else                                     :anonymous
      end
    add_roles(prototype_user)
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  private

  # Add EMMA role(s) to the current user based on its prototype.
  #
  # @param [Symbol] prototype_user    @see `Roles#DEFAULT_ROLES.keys`.
  #
  # @return [Array<Role>]             Added role(s).
  #
  def add_roles(prototype_user)
    added_roles = DEFAULT_ROLES[prototype_user] || DEFAULT_ROLES[:anonymous]
    added_roles.map { |role| add_role(role) }
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Get (or create) a database entry for the indicated user and update the
  # associated User object with additional information from the provider.
  #
  # @param [OmniAuth::AuthHash, Hash, nil] data
  #
  # @return [User]
  # @return [nil]                     If *data* is not valid.
  #
  # @see https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
  #
  def self.from_omniauth(data)
    return unless data.is_a?(Hash)
    data = OmniAuth::AuthHash.new(data) unless data.is_a?(OmniAuth::AuthHash)
    find_or_create_by(email: data.uid.downcase).tap do |user|
      # user.email       = auth.info.email
      user.first_name    = data.info.first_name
      user.last_name     = data.info.last_name
      user.access_token  = data.credentials.token
      user.refresh_token = data.credentials.refresh_token
    end
  end

end

__loading_end(__FILE__)
