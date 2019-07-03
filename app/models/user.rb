# app/models/user.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for the representation of an EMMA/Bookshare user.
#
# NOTE: Section 1.8 of the API documentation ("User Types") is TBD.
#
# == Implementation Notes
# NOTE: There is still some friction between the concepts of User and Member.
#
# === Documented "types" of "users"
# Section 2.2 of the API documentation mentions "Membership Assistants" and
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

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :omniauthable,
         omniauth_providers: User::OmniauthCallbacksController::PROVIDERS

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  rolify

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Hash, nil] attributes
  #
  def initialize(attributes = nil)
    super
    # NOTE: for temporary test users
    case uid
      when 'emmacollection@bookshare.org'
        find_or_create_by(email: uid)
        add_role(:administrator)
      when 'emmadso@bookshare.org'
        find_or_create_by(email: uid)
        add_role(:membership_manager)
    end
    add_role(DEFAULT_EMMA_ROLE) if roles.blank?
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
  # :section: Class methods
  # ===========================================================================

  public

  # Get (or create) a database entry for the indicated user and update the
  # associated User object with additional information from the provider.
  #
  # @param [Hash, OmniAuth::AuthHash] data
  #
  # @return [User]
  #
  # @see https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
  #
  def self.from_omniauth(data)
    return unless data.is_a?(Hash)
    data = OmniAuth::AuthHash.new(data)
    find_or_create_by(email: data.uid).tap do |user|
      # user.email       = auth.info.email
      user.first_name    = data.info.first_name
      user.last_name     = data.info.last_name
      user.access_token  = data.credentials.token
      user.refresh_token = data.credentials.refresh_token
    end
  end

end

__loading_end(__FILE__)
