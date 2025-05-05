# app/models/org.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

#--
# noinspection RubyTooManyMethodsInspection
#++
class Org < ApplicationRecord

  include ActiveRecord::AttributeMethods::Dirty

  include Model

  include Record
  include Record::Assignable
  include Record::Searchable
  include Record::Sortable

  include Record::Testing
  include Record::Debugging

  include Org::Config
  include Org::Assignable

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Record::Rendering
    extend  Record::Rendering
  end
  # :nocov:

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :long_name

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  has_many :users

  has_many :uploads,   -> { order(Upload.default_sort) },   through: :users
  has_many :manifests, -> { order(Manifest.default_sort) }, through: :users
  has_many :downloads, -> { order(Download.default_sort) }, through: :users

  # ===========================================================================
  # :section: ActiveRecord scopes
  # ===========================================================================

  scope :active,       -> { where.not(status: :inactive) }
  scope :inactive,     -> { where(status: :inactive) }

  # ===========================================================================
  # :section: ActiveRecord callbacks
  # ===========================================================================

  before_update :update_users

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # A short textual representation for the record instance.
  #
  # @param [Org, nil] item            Default: self.
  #
  # @return [String, nil]
  #
  def abbrev(item = nil)
    (item || self).short_name.presence
  end

  # A textual label for the record instance.
  #
  # @param [Org, nil] item  Default: self.
  #
  # @return [String, nil]
  #
  def label(item = nil)
    (item || self).long_name.presence
  end

  # Create a new instance.
  #
  # @param [Org, Hash, nil] attr   Passed to #assign_attributes via super.
  #
  # @note - for dev traceability
  #
  def initialize(attr = nil)
    super
  end

  def org_id = id

  # ===========================================================================
  # :section: IdMethods overrides
  # ===========================================================================

  public

  def org_key = ID_COLUMN

  def self.org_key = ID_COLUMN

  def uid(item = nil)
    item ? super : not_applicable(log: true)
  end

  def self.for_user(user = nil, **opt)
    user = extract_value!(user, opt, :user, __method__)
    where(user: user, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The 'users' table IDs of users associated with this organization.
  #
  # @return [Array<Integer>]
  #
  def user_ids
    users.pluck(:id)
  end

  # The account names of users associated with this organization.
  #
  # @return [Array<String>]
  #
  # @note Currently unused.
  # :nocov:
  def user_accounts
    users.pluck(:email)
  end
  # :nocov:

  # The number of EMMA entries submitted by users of this organization.
  #
  # @return [Integer]
  #
  def upload_count
    uploads.count
  end

  # The number of bulk manifests associated with users of this organization.
  #
  # @return [Integer]
  #
  def manifest_count
    manifests.count
  end

  # A relation for all organization contact users.
  #
  # @return [ActiveRecord::Relation<User>]
  #
  def contacts
    contact.present? ? User.where(id: contact) : User.none
  end

  # A relation for all organization managers.
  #
  # @return [ActiveRecord::Relation<User>]
  #
  def managers
    users.where(role: RolePrototype(:manager).to_s)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the common name of *org*.
  #
  # @param [any, nil] org             User, String, Symbol, Integer; def: self
  #
  # @return [String, nil]
  #
  def org_name(org = nil)
    self.class.send(__method__, (org || self))
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Return the common name of *org*.
  #
  # @note This method assumes that if *org* is a String or Symbol it already
  #   represents an organization name unless it resolves to an org ID.
  #
  # @param [any, nil] org             User, String, Symbol, Integer
  #
  # @return [String, nil]
  #
  def self.org_name(org)
    return                if org.blank?
    org = org.to_s        if org.is_a?(Symbol)
    org = oid(org) || org if org.is_a?(String)
    org.is_a?(String) ? org : instance_for(org)&.abbrev
  end

  # Ensure that :long_name is present and that :short_name is valid or can be
  # derived from :long_name.
  #
  # @param [Hash] attr
  # @param [Hash] opt           To #normalize_long_name, #normalize_short_name
  #
  # @return [Hash]              The possibly-modified *attr*.
  #
  def self.normalize_names!(attr, **opt)
    long_name  = normalize_long_name(attr[:long_name], **opt)
    short_name = attr[:short_name] || abbreviate_org(long_name.to_s)
    attr[:long_name]  = long_name
    attr[:short_name] = normalize_short_name(short_name, **opt)
    attr
  end

  # Normalize a :long_name value.
  #
  # @param [any, nil]       value
  # @param [Boolean, Class] fatal     If *true* defaults to RuntimeError.
  #
  # @raise [Record::SubmitError]      If *value* is not acceptable for *field*.
  #
  # @return [String]                  Normalized value.
  # @return [nil]                     If missing and not fatal.
  #
  def self.normalize_long_name(value, fatal: false, **)
    value = value.to_s.squish.presence
    error = ('Missing %{field}' if value.blank?) # TODO: I18n

    return value.upcase_first unless error

    error %= { field: 'organization name' } # TODO: I18n
    Log.info { "#{__method__} #{error}" }
    raise (fatal.is_a?(Class) ? fatal : RuntimeError), error if fatal
  end

  # Normalize a :short_name value.
  #
  # @param [any, nil]       value
  # @param [Boolean, Class] fatal     If *true* defaults to RuntimeError.
  #
  # @raise [Record::SubmitError]      If *value* is not acceptable for *field*.
  #
  # @return [String]                  Normalized value.
  # @return [nil]                     If missing and not fatal.
  #
  def self.normalize_short_name(value, fatal: false, **)
    value = value.to_s.squish
    error =
      if value.blank?
        'Missing %{field}' # TODO: I18n
      elsif (value = value.gsub(/[^[:alnum:]]/, '')).blank?
        'Please use only letters or numbers for %{field}' # TODO: I18n
      elsif value.start_with?(/\d/)
        'Please begin %{field} with a letter' # TODO: I18n
      end

    return value unless error

    error %= { field: 'abbreviation' } # TODO: I18n
    Log.info { "#{__method__} #{error}" }
    raise (fatal.is_a?(Class) ? fatal : RuntimeError), error if fatal
  end

  # This is the (non-persisted) organization associated with ID 0.
  #
  # User records use :org_id == 0 to indicate that the user is explicitly not
  # associated with any member organization, whereas a NIL field value
  # indicates that the user's organization has not yet been determined.
  #
  # @return [Org]
  #
  def self.none
    @null ||= new(
      id:           INTERNAL_ID,
      short_name:   INTERNAL[:short_name],
      long_name:    INTERNAL[:long_name],
      status:       :active,
      status_date:  (t0 = DateTime.new(0)),
      start_date:   t0,
      created_at:   t0,
      updated_at:   t0,
      attr_opt:     { force: ignored_keys }
    )
  end

  # Return the Org instance indicated by the argument.
  #
  # @param [any, nil] v               Model, Hash, String, Integer
  #
  # @return [Org, nil]                A fresh record unless *v* is an Org.
  #
  def self.instance_for(v)
    v &&= try_key(v, model_key) || v
    return v if v.is_a?(self) || v.nil?
    case (v = oid(v) || v)
      when INTERNAL_ID then none
      when Integer     then find_by(id: v)
      when String      then where(short_name: v).or(where(long_name: v)).first
      when Hash        then find_by(v) if (v = v.slice(*field_names)).present?
    end
  end

  # ===========================================================================
  # :section: ActiveRecord callbacks
  # ===========================================================================

  protected

  # If organization status transitions to :active or :inactive, transition all
  # organization users to the same status.
  #
  # @return [void]
  #
  # @see ActiveRecord::AttributeMethods::Dirty
  #
  def update_users
    old_status, new_status = status_in_database&.to_sym, status&.to_sym
    case new_status
      when :active   then return if old_status != :inactive
      when :inactive then return if old_status == :inactive
      else                return
    end
    users.each { _1.update_column(:status, new_status) }
  end

end

__loading_end(__FILE__)
