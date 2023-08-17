# app/models/user.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for the representation of an EMMA user.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
class User < ApplicationRecord

  include Emma::Common

  include Model

  include Record
  include Record::Identification
  include Record::Searchable

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Rolify
    include Rolify::Role
    include Devise::Models::DatabaseAuthenticatable
    include Devise::Models::Rememberable
    include Devise::Models::Trackable
    include Devise::Models::Registerable
    include Devise::Models::Omniauthable
    extend  ActiveRecord::Validations
    # :nocov:
  end

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :id

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  belongs_to :org, optional: true

  has_many :search_calls
  has_many :uploads
  has_many :manifests

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Include default devise modules.
  devise :database_authenticatable,
  #      :confirmable,
  #      :lockable,
         :recoverable,
         :registerable,
         :rememberable,
  #      :timeoutable,
         :trackable,
  #      :validatable,
         :omniauthable, omniauth_providers: AUTH_PROVIDERS

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  rolify

  # ===========================================================================
  # :section: ActiveRecord validations
  # ===========================================================================

  validate on: :create do
    unless account.match?(/^.+@.+$/)
      errors.add(:base, message: 'User ID must be a valid email address')
    end
  end

  # ===========================================================================
  # :section: ActiveRecord callbacks
  # ===========================================================================

  after_create :assign_default_role

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # A textual label for the record instance.
  #
  # @param [User, nil] item  Default: self.
  #
  # @return [String, nil]
  #
  def label(item = nil)
    (item || self).account.presence
  end

  # The controller for the model/model instance.
  #
  # @type [Class]
  #
  def self.model_controller
    AccountController
  end

  # Create a new instance.
  #
  # @param [User, Hash, nil] attr
  #
  # @note - for dev traceability
  #
  def initialize(attr = nil)
    super
  end

  # ===========================================================================
  # :section: IdMethods overrides
  # ===========================================================================

  public

  def user_id = id

  def org_id = org&.id

  def user_key = ID_COLUMN

  def self.user_key = ID_COLUMN

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Display the User instance as the user identifier.
  #
  # @return [String]
  #
  def to_s
    account.to_s
  end

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # Value of :id for the indicated record.
  #
  # @param [User, String, Integer, *] user  Default: self
  # @param [Hash]                     opt
  #
  # @return [String]
  # @return [nil]                     If no matching record was found.
  #
  def id_value(user = nil, **opt)
    return id&.to_s if user.nil? && opt.blank?
    self.class.send(__method__, (user || self), **opt)
  end

  # Value of :id for the indicated record.
  #
  # @param [User, String, Integer, *] user
  # @param [Hash]                     opt
  #
  # @return [String]
  # @return [nil]                     If no matching record was found.
  #
  def self.id_value(user, **opt)
    user = find_record(user) if user.is_a?(String) && !digits_only?(user)
    super(user, **opt)
  end

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  def user_column = user_key

  def self.user_column = user_key

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # Return with the specified User record or *nil* if one could not be found.
  #
  # @param [String, Integer, Hash, Model, *] item
  # @param [Hash]                            opt
  #
  # @return [User, nil]
  #
  def find_record(item, **opt)
    self.class.send(__method__, item, **opt)
  end

  # Return with the specified User record or *nil* if one could not be found.
  #
  # @param [String, Symbol, Integer, Hash, Model, Any, nil] item
  # @param [Hash]                                           opt
  #
  # @option opt [Boolean] :no_raise   True by default.
  #
  # @return [User, nil]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def self.find_record(item, **opt)
    item = item.to_s if item.is_a?(Symbol)
    if item.is_a?(String) && !digits_only?(item)
      find_by(email: item)
    else
      opt[:no_raise] = true unless opt.key?(:no_raise)
      super
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def ability
    @ability ||= Ability.new(self)
  end

  delegate :can?, :cannot?, to: :ability

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the account ID of *user*.
  #
  # @param [User, String, Symbol, Integer, Any, nil] user  Default: self.
  #
  # @return [String, nil]
  #
  def account_name(user = nil)
    user ? self.class.send(__method__, user) : email.presence
  end

  # Return the account ID of *user*.
  #
  # @param [User, String, Symbol, Integer, Any, nil] user
  #
  # @return [String, nil]
  #
  def self.account_name(user)
    user = positive(user) || user
    user = find(user) if user.is_a?(Integer)
    user = user.email if user.is_a?(User)
    user = user.to_s  if user.is_a?(Symbol)
    user.presence     if user.is_a?(String)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The user ID is the same as the email address.                               # unless BS_AUTH
  #
  # The user ID is the same as the Bookshare ID, which is the same as the email # if BS_AUTH
  # address.
  #
  # @return [String]
  #
  def account
    email
  end

  # Address to use for email communication with the user.
  #
  # @return [String]
  #
  def email_address
    preferred_email || email
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the user is one of the known "fake" test user accounts.
  #
  def test_user?
    test_users.keys.include?(account)
  end

  # Indicate whether the user has the :developer role.
  #
  def developer?
    @developer = has_role?(:developer) if @developer.nil?
    @developer
  end

  # Indicate whether the user has the :administrator role.
  #
  def administrator?
    @administrator = has_role?(:administrator) if @administrator.nil?
    @administrator
  end

  # Indicate whether the user has the :manager role.
  #
  def manager?
    @manager = has_role?(:manager) if @manager.nil?
    @manager
  end

  # The user's EMMA roles.
  #
  # @return [Array<Symbol>]
  #
  def role_list
    roles.map(&:name).map(&:to_sym)
  end

  # ===========================================================================
  # :section: ActiveRecord callbacks
  # ===========================================================================

  protected

  # assign_default_role
  #
  # @return [void]
  #
  # === Implementation Notes
  # A new User will be created the first time a new person authenticates via    # if BS_AUTH
  # Bookshare -- this may be the place to query the Bookshare API for that
  # user's Bookshare role in order to map it onto EMMA "prototype user".
  #
  def assign_default_role
    prototype_user = account.blank? ? :anonymous : test_users[account]
    add_roles(prototype_user)
  end

  # ===========================================================================
  # :section: ActiveRecord callbacks
  # ===========================================================================

  private

  # Add EMMA role(s) to the current user based on its prototype.
  #
  # @param [Symbol, nil] prototype    Default: `Role#DEFAULT_PROTOTYPE`.
  #
  # @return [Array<Role>]             Added role(s).
  #
  def add_roles(prototype = nil)
    prototype ||= Role::DEFAULT_PROTOTYPE
    added_roles = Role::PROTOTYPE[prototype]
    if added_roles.blank?
      Log.error("#{__method__}: invalid prototype #{prototype.inspect}")
      added_roles = Role::PROTOTYPE[:anonymous]
    end
    added_roles.map { |role| add_role(role) }
  end

  # ===========================================================================
  # :section: Rolify::Role overrides
  # ===========================================================================

  public

  # Extend Rolify #has_role? to first check for role prototype.
  #
  # Always returns *false* if *role* is blank.
  #
  # @param [String, Symbol, nil]                   role
  # @param [Symbol, Class, ApplicationRecord, nil] resource
  #
  def has_role?(role, resource = nil)
    return false if role.blank?
    role = role.to_s.strip.to_sym if role.is_a?(String)
    # noinspection RubyMismatchedArgumentType
    if resource.nil?
      (role == Role.prototype_for(self)) || super(role)
    elsif resource.is_a?(User)
      (role == Role.prototype_for(resource)) || super(role, resource)
    else
      super(role, resource)
    end
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  delegate :test_users, to: :class

  # Current EMMA test accounts.
  #
  # @type [Hash{String=>Symbol}]
  #
  def self.test_users
    # noinspection RbsMissingTypeSignature
    @test_users ||=
      begin
        test_names = %w[test\\_%@%]
        test_names << 'emma%@bookshare.org' if BS_AUTH
        uid_like   = test_names.map { 'email LIKE ?' }.join(' OR ')
        where(uid_like, *test_names).map { |u|
          [u.email, Role.prototype_for(u)]
        }.to_h
      end
  end

  # Get the database entry for the indicated user and update it with additional # unless BS_AUTH
  # information from the provider.
  #
  # Get (or create) a database entry for the indicated user and update the      # if BS_AUTH
  # associated User object with additional information from the provider.
  #
  # @param [OmniAuth::AuthHash, Hash, nil] data
  # @param [Boolean]                       update   If *false* keep DB record.
  #
  # @return [User]                    Updated record of the indicated user.
  # @return [nil]                     If *data* is not valid.
  #
  # @see https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
  #
  def self.from_omniauth(data, update: true)
    return unless data.is_a?(Hash)
    data = OmniAuth::AuthHash.new(data) unless data.is_a?(OmniAuth::AuthHash)
    # noinspection RubyResolve
    attr = {
      email:         data.uid.downcase,
      first_name:    data.info&.first_name || data.info&.givenName,
      last_name:     data.info&.last_name || data.info&.sn,
      access_token:  (data.credentials&.token         if BS_AUTH),
      refresh_token: (data.credentials&.refresh_token if BS_AUTH),
      provider:      data.provider,
    }.compact_blank!
    user = find_by(email: attr[:email])
    if user && update
      attr.delete(:email)
      attr.delete(:first_name) if user.first_name.present?
      attr.delete(:last_name)  if user.last_name.present?
      user.update(attr) if attr.delete_if { |k, v| user[k] == v }.present?
    end
    # Disable automatic account creation
    # user ||= create(attr) if BS_AUTH
    user
  end

end

__loading_end(__FILE__)
