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

  self.implicit_order_column = :created_at

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  has_many :search_calls
  has_many :uploads
  has_many :manifests

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :recoverable, :validatable
  devise :database_authenticatable, :rememberable, :trackable, :registerable,
         :omniauthable, omniauth_providers: AUTH_PROVIDERS

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  rolify

  # ===========================================================================
  # :section: ActiveRecord validations
  # ===========================================================================

  validate on: :create do
    unless uid.match?(/^.+@.+$/)
      errors.add(:base, message: 'User ID must be a valid email address')
    end
  end

  # ===========================================================================
  # :section: ActiveRecord callbacks
  # ===========================================================================

  after_create :assign_default_role

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
  # :section: ActiveRecord overrides
  # ===========================================================================

  public

  # Update database fields.                                                     # if BS_AUTH
  #
  # @param [User, Hash, nil] attributes
  #
  # @return [void]
  #
  def assign_attributes(attributes)
    old_eid = self[:effective_id]
    super
    new_eid = self[:effective_id]
    add_role(:administrator) if new_eid && (new_eid != old_eid)
  end if BS_AUTH

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # Value of :id for the indicated record.
  #
  # @param [User, String, Integer, Any] user  Default: self
  # @param [Hash]                       opt
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
  # @param [User, String, Integer, Any] user
  # @param [Hash]                       opt
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

  def user_column
    :id
  end

  def self.user_column
    :id
  end

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # Return with the specified User record or *nil* if one could not be found.
  #
  # @param [String, Symbol, Integer, Hash, Model, Any, nil] item
  # @param [Hash]                                           opt
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

  # Return the account ID of *user*.
  #
  # @param [User, String, Symbol, Integer, Any, nil] user  Default: self.
  #
  # @return [String, nil]
  #
  def uid_value(user = nil)
    return uid.presence if user.nil?
    self.class.send(__method__, user)
  end

  # Return the account ID of *user*.
  #
  # @param [User, String, Symbol, Integer, Any, nil] user
  #
  # @return [String, nil]
  #
  def self.uid_value(user)
    user = user.to_s  if user.is_a?(Symbol)
    user = user.to_i  if digits_only?(user)
    user = find(user) if user.is_a?(Integer) && user.positive?
    user = user.uid   if user.is_a?(User)
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
  def uid
    email
  end

  # Indicate whether this User is represented by a different Bookshare user.    # if BS_AUTH
  #
  # The Bookshare ID associated with this account if different from *self*.
  #
  # @return [String]
  # @return [nil]
  #
  def effective_uid
    effective_user&.uid
  end
    .tap { |meth| disallow(meth) unless BS_AUTH }

  # The User who interacts with Bookshare on behalf of this account if          # if BS_AUTH
  # different from *self*.
  #
  # @return [User]
  # @return [nil]
  #
  def effective_user
    User.find(effective_id) if effective_id.present?
  end
    .tap { |meth| disallow(meth) unless BS_AUTH }

  # Indicate whether this account directly maps on to a Bookshare account.      # if BS_AUTH
  #
  def is_bookshare_user?
    effective_id.blank?
  end
    .tap { |meth| disallow(meth) unless BS_AUTH }

  # The Bookshare ID associated with this account.                              # if BS_AUTH
  #
  # @return [String]
  #
  def bookshare_uid
    bookshare_user.uid
  end
    .tap { |meth| disallow(meth) unless BS_AUTH }

  # The User who interacts with Bookshare on behalf of this account.            # if BS_AUTH
  #
  # This is *self* unless :effective_id is non-null.
  #
  # @return [User]
  #
  def bookshare_user
    @bookshare_user ||= effective_user || self
  end
    .tap { |meth| disallow(meth) unless BS_AUTH }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the user is one of the known "fake" test user accounts.
  #
  def test_user?
    test_users.keys.include?(uid)
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

  # The user's EMMA roles.
  #
  # @return [Array<Symbol>]
  #
  def role_list
    roles.map(&:name).map(&:to_sym)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # menu_label
  #
  # @param [User, nil] item           Default: self.
  #
  # @return [String, nil]
  #
  # @see BaseDecorator::Menu#items_menu_label
  #
  def menu_label(item = nil)
    (item || self).uid.presence
  end

  # ===========================================================================
  # :section: ActiveRecord callbacks
  # ===========================================================================

  protected

  # assign_default_role
  #
  # @return [void]
  #
  # == Implementation Notes
  # A new User will be created the first time a new person authenticates via    # if BS_AUTH
  # Bookshare -- this may be the place to query the Bookshare API for that
  # user's Bookshare role in order to map it onto EMMA "prototype user".
  #
  def assign_default_role
    prototype_user = uid.blank? ? :anonymous : test_users[uid]
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
  # @param [String, Symbol] role      Role capability or role prototype.
  # @param [Symbol, nil]    resource
  #
  def has_role?(role, resource = nil)
    if resource.nil?
      role = role.to_s.strip.to_sym if role.is_a?(String)
      return true if role == Role.prototype_for(self)
    end
    super(role, resource)
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
        test_names = %w(test\\_%@virginia.edu)
        test_names << 'emma%@bookshare.org' if BS_AUTH
        uid_like   = test_names.map { |p| 'email LIKE ?' }.join(' OR ')
        where(uid_like, *test_names).map { |u|
          [u.email, Role.prototype_for(u)]
        }.to_h
      end
  end

  # Pairs of current EMMA test Bookshare accounts with their "users" table      # if BS_AUTH
  # record IDs.
  #
  # @type [Array<(String,Integer)>]
  #
  def self.test_user_menu
    # noinspection RailsParamDefResolve
    where(email: test_users.keys).pluck(:email, :id)
  end
    .tap { |meth| disallow(meth) unless BS_AUTH }

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
    user ||= create(attr) if BS_AUTH
    user
  end

end

__loading_end(__FILE__)
