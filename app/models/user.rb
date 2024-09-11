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
  include Record::Assignable
  include Record::Identification
  include Record::Searchable
  include Record::Sortable

  include User::Config
  include User::Assignable
  include User::Identification

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
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

  has_many :search_calls, -> { order(SearchCall.default_sort) }
  has_many :uploads,      -> { order(Upload.default_sort) }
  has_many :manifests,    -> { order(Manifest.default_sort) }

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
  # :section: ActiveRecord validations
  # ===========================================================================

  validate on: :create do
    unless account.match?(/^.+@.+$/)
      errors.add(:base, message: 'User ID must be a valid email address')
    end
  end

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # A short textual representation for the record instance.
  #
  # @param [User, nil] item           Default: self.
  #
  # @return [String, nil]
  #
  def abbrev(item = nil)
    (item || self).account.presence
  end

  # A textual label for the record instance.
  #
  # @param [User, nil] item  Default: self.
  #
  # @return [String, nil]
  #
  def label(item = nil)
    (item || self).account.presence
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

  def user_id = id

  def org_id = self[:org_id]

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # Symbolic name of the controller associated with the model/model instance.
  #
  # @type [Symbol]
  #
  def self.ctrlr_type
    :account
  end

  # ===========================================================================
  # :section: IdMethods overrides
  # ===========================================================================

  public

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
  # :section:
  # ===========================================================================

  public

  def ability
    @ability ||= Ability.new(self)
  end

  delegate :can?, :cannot?, :role_prototype, :capabilities, to: :ability

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the account ID of *user*.
  #
  # @param [any, nil] user            User, String, Symbol, Integer; def: self.
  #
  # @return [String, nil]
  #
  def account_name(user = nil)
    self.class.send(__method__, (user || self))
  end

  # Return the account ID of *user*.
  #
  # @note This method assumes that if *user* is a String or Symbol it already
  #   represents an account name unless it resolves to a user ID.
  #
  # @param [any, nil] user            User, String, Symbol, Integer
  #
  # @return [String, nil]
  #
  def self.account_name(user)
    return                   if user.blank?
    user = user.to_s         if user.is_a?(Symbol)
    user = uid(user) || user if user.is_a?(String)
    user.is_a?(String) ? user : instance_for(user)&.email&.presence
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The user ID is the same as the email address.
  #
  # @return [String]
  #
  def account
    email
  end

  # The full personal name of the user.
  #
  # @return [String]
  #
  def full_name
    [first_name, last_name].compact_blank.join(' ')
  end

  # The email address to use for communications with the user.
  #
  # @return [String]
  #
  def email_address
    preferred_email || email
  end

  # The number of EMMA entries submitted by this user.
  #
  # @return [Integer]
  #
  def upload_count
    uploads.count
  end

  # The number of bulk upload manifests associated with this user.
  #
  # @return [Integer]
  #
  def manifest_count
    manifests.count
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
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def developer?
    @developer = has_role?(:developer) if @developer.nil?
    @developer
  end

  # Indicate whether the user has the :administrator role.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def administrator?
    @administrator = has_role?(:administrator) if @administrator.nil?
    @administrator
  end

  # Indicate whether the user has the :manager role.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def manager?
    @manager = has_role?(:manager) if @manager.nil?
    @manager
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Check for role prototype or role capability.
  #
  # Always returns *false* if *value* is blank.
  #
  # @param [RolePrototype, RoleCapability, String, Symbol, nil] value
  #
  def has_role?(value)
    return false if value.blank?
    if (role = RolePrototype.cast(value)).valid?
      (role_prototype == role) ||
        capabilities.any? do |c|
          Ability::CAPABILITY_ROLE[c.to_sym] == role.to_sym
        end
    elsif (cap = RoleCapability.cast(value)).valid?
      capabilities.include?(cap)
    else
      Log.error("#{__method__}: invalid: #{value.inspect}") or false
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
        email_like = test_names.map { 'email LIKE ?' }.join(' OR ')
        where(email_like, *test_names).map { [_1.email, _1.role] }.to_h
      end
  end

  # Get the database entry for the indicated user and update it with additional
  # information from the provider.
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
      email:      data.uid.downcase,
      first_name: data.info&.first_name || data.info&.givenName,
      last_name:  data.info&.last_name  || data.info&.sn,
      provider:   data.provider,
    }.compact_blank!
    find_by(email: attr[:email]).tap do |user|
      if user && update
        attr.delete(:email)
        attr.delete(:first_name) if user.first_name.present?
        attr.delete(:last_name)  if user.last_name.present?
        user.update(attr) if attr.delete_if { user[_1] == _2 }.present?
      end
    end
  end

  # Return the User instance indicated by the argument.
  #
  # @param [any, nil] v               Model, Hash, String, Integer
  #
  # @return [User, nil]               A fresh record unless *v* is a User.
  #
  def self.instance_for(v)
    v &&= try_key(v, model_key) || v
    return v if v.is_a?(self) || v.nil?
    # noinspection RubyMismatchedReturnType
    case (v = uid(v) || v)
      when Integer then find_by(id: v)
      when String  then where(email: v).or(where(preferred_email: v)).first
      when Hash    then find_by(v) if (v = v.slice(*field_names)).present?
    end
  end

end

__loading_end(__FILE__)
