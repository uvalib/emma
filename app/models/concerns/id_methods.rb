# app/models/concerns/id_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module IdMethods

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  ID_COLUMN   = :id
  USER_COLUMN = :user_id
  ORG_COLUMN  = :org_id

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def user_key = USER_COLUMN

  def org_key  = ORG_COLUMN

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The explicit :user_id field if a record defines it, or the method defined
  # by the record to derive the ID of the User associated with the record
  # instance.
  #
  # @param [any, nil] item
  # @param [Symbol]   key
  #
  # @return [Integer, nil]
  #
  def uid(item, key = USER_COLUMN)
    item.is_a?(User) ? item.id : get_id(item, key)
  end

  # The explicit :org_id field if a record defines it, or the method defined
  # by the record to derive the ID of the Organization associated with the
  # record instance.
  #
  # @param [any, nil] item
  # @param [Symbol]   key
  #
  # @return [Integer, nil]
  #
  def oid(item, key = ORG_COLUMN)
    item.is_a?(Org) ? item.id : get_id(item, key, allow_zero: true)
  end

  # Get the specified identity value from *item*.
  #
  # @param [any, nil] item
  # @param [Symbol]   key
  # @param [Boolean]  allow_zero
  #
  # @return [Integer, nil]
  #
  def get_id(item, key, allow_zero: false)
    item = try_key(item, key) || item
    allow_zero ? non_negative(item) : positive(item)
  end

  # Get the specified value from *item*.
  #
  # @param [any, nil] item
  # @param [Symbol]   key
  #
  # @return [any, nil]
  #
  def try_key(item, key)
    case item
      when ApplicationRecord then item.try(key) || item[key]
      when Hash              then item[key]     || item[key.to_s]
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def normalize_id_keys(arg, target = nil)
    return arg unless arg.is_a?(Hash) && arg.present?
    normalize_id_keys!(arg.dup, target)
  end

  def normalize_id_keys!(hash, target = nil)
    target_type = target&.model_type
    model_types = ApplicationRecord.model_types
    hash.extract!(*model_types).each_pair do |model, val|
      key = (model == target_type) ? :id : :"#{model}_id"
      Log.warn {
        "#{__method__}: #{key}: now #{val.inspect}; was: #{hash[key].inspect}"
      } if hash.key?(key)
      hash[key] = val
    end
    id_or_value = ->(v) { v.is_a?(ApplicationRecord) ? v.id : v }
    hash.transform_values! do |val|
      val.is_a?(Array) ? val.map(&id_or_value) : id_or_value.(val)
    end
  end

  # ===========================================================================
  # :section: Instance methods
  # ===========================================================================

  public

  module InstanceMethods

    include IdMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def uid(item = nil)
      item ||= self
      super
    end

    def oid(item = nil)
      item ||= self
      super
    end

  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Class methods automatically added to the including class.
  #
  module ClassMethods

    include IdMethods

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveRecord::QueryMethods
      # :nocov:
    end

    # =========================================================================
    # :section: IdMethods overrides
    # =========================================================================

    public

    def uid(item)
      item ? super : not_applicable
    end

    def oid(item)
      item ? super : not_applicable
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Produce a relation for selecting records associated with the given user.
    #
    # @param [any, nil] user
    # @param [Hash]     opt
    #
    # @return [ActiveRecord::Relation]
    #
    def for_user(user = nil, **opt)
      user = extract_value!(user, opt, :user, __method__)
      user = uid(user)
      # noinspection RubyMismatchedReturnType
      where(user_key => user, **opt)
    end

    # Produce a relation for selecting records associated with the given
    # organization.
    #
    # @param [any, nil] org
    # @param [Hash]     opt
    #
    # @return [ActiveRecord::Relation]
    #
    def for_org(org = nil, **opt)
      org = extract_value!(org, opt, :org, __method__)
      org = oid(org)
      # noinspection RubyMismatchedReturnType
      where(org_key => org, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    def extract_value!(item, opt, base, meth = nil)
      prm = opt.extract!(:"#{base}", :"#{base}_id").compact.values.first
      item || prm ||
        (Log.warn { "#{meth}: no #{base} in #{opt.inspect}" } if meth)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    return unless Record.record_class?(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)
  end

end

__loading_end(__FILE__)
