# app/models/org.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

#--
# noinspection RubyTooManyMethodsInspection
#++
class Org < ApplicationRecord

  include Model

  include Record
  include Record::Assignable
  include Record::Searchable

  include Record::Testing
  include Record::Debugging

  include Org::Config
  include Org::Assignable

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :long_name

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  has_many :users

  has_many :uploads,   through: :users
  has_many :manifests, through: :users

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
  def initialize(attr = nil, &blk)
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
    # noinspection RubyMismatchedReturnType
    users.pluck(:id)
  end

  # The account names of users associated with this organization.
  #
  # @return [Array<String>]
  #
  # @note Currently unused.
  #
  def user_accounts
    # noinspection RubyMismatchedReturnType
    users.pluck(:email)
  end

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

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # This is the (non-persisted) organization associated with ID 0.
  #
  # User records use :org_id == 0 to indicate that the user is explicitly not
  # associated with any member organization, whereas a NIL field value
  # indicates that the user's organization has not yet been determined.
  #
  # @return [Org]
  #
  def self.none
    # noinspection RbsMissingTypeSignature
    @null ||= new(
      id:           INTERNAL_ID,
      short_name:   INTERNAL_NAME,
      long_name:    '(no organization)', # TODO: I18n
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
  # @param [Model, Hash, String, Integer, nil] v
  #
  # @return [Org, nil]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def self.instance_for(v)
    v = v.values_at(:org, :org_id).first if v.is_a?(Hash)
    return                               if v.nil?
    return v                             if v.is_a?(Org)
    v = v.oid                            if v.is_a?(ApplicationRecord)
    case (v = non_negative(v) || v)
      when INTERNAL_ID then none
      when Integer     then find_by(id: v)
      when String      then where('(short_name=?) OR (long_name=?)',v,v).first
    end
  end

end

__loading_end(__FILE__)
