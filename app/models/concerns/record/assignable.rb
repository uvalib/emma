# app/models/record/assignable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods relating to record field assignment.
#
module Record::Assignable

  extend ActiveSupport::Concern

  include Record
  include Record::Identification

  include SqlMethods

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActiveRecord::Core
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Called to prepare values to be used for assignment to record attributes.
  #
  # The return is record field values along with :attr_opt holding all options
  # passed into the method either through *opt* or through *attr* if it is a
  # Hash.
  #
  # @param [Model, Hash, ActionController::Parameters, nil] attr
  # @param [Hash, nil]                                      opt
  #
  # @option opt [ApplicationRecord]            :from        A record used to provide initial field values.
  # @option opt [User, String, Integer]        :user        Transformed into a :user_id value.
  # @option opt [Symbol, Array<Symbol>]        :force       Allow these fields unconditionally.
  # @option opt [Symbol, Array<Symbol>]        :except      Ignore these fields (default: []).
  # @option opt [Symbol, Array<Symbol>, false] :only        Not limited if *false* (default: `#field_name`).
  # @option opt [Boolean]                      :compact     If *false*, allow blanks (default: *true*).
  # @option opt [Boolean]                      :key_norm    If *true*, transform provided keys to the real column name.
  # @option opt [Boolean]                      :normalized  If *attr* already processed by #normalize_attributes.
  # @option opt [Hash]                         :attr_opt    A hash containing any of the above values.
  #
  # @raise [RuntimeError]             If the type of *attr* is invalid.
  #
  # @return [Hash{Symbol=>*}]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def normalize_attributes(attr, opt = nil)
    opt = opt ? (opt[:attr_opt]&.dup || {}).merge!(opt.except(:attr_opt)) : {}
    opt = attr[:attr_opt].merge(opt) if attr.is_a?(Hash) && attr[:attr_opt]

    if attr.is_a?(Hash) && attr.dig(:attr_opt, :normalized)
      return attr.merge(attr_opt: opt)
    elsif attr.is_a?(Hash)
      attr = attr.except(:attr_opt)
    elsif attr.respond_to?(:params)
      attr = attr.params.to_unsafe_h
    elsif attr.respond_to?(:to_unsafe_h)
      attr = attr.to_unsafe_h
    elsif attr.is_a?(ApplicationRecord)
      unless attr.is_a?(record_class)
        Log.warn { "#{record_class}: assigning from a #{attr.class} record" }
      end
      attr = attr.fields.except!(*ignored_keys)
    elsif attr.nil?
      attr = {}
    else
      raise "#{attr.class}: unexpected"
    end

    from    = opt[:from]
    from  &&= normalize_attributes(from, except: ignored_keys)
    user    = from&.extract!(:user, :user_id)&.compact&.values&.first
    user    = attr.extract!(:user, :user_id).compact.values.first || user
    user    = opt.extract!(:user, :user_id).compact.values.first || user
    force   = Array.wrap(opt[:force])
    excp    = Array.wrap(opt[:except]) - force
    only    = !false?(opt[:only]) && Array.wrap(opt[:only] || allowed_keys)
    compact = !false?(opt[:compact])
    options = [opt[:options], from&.delete(:options)].compact.first

    attr.reverse_merge!(from) if from.present?

    attr.transform_keys! { |k| k.to_s.delete_suffix('[]').to_sym }
    attr.transform_keys! { |k| normalize_key(k) } if true?(opt[:key_norm])

    attr.merge!(user_id: user)   if (user &&= User.id_value(user))
    attr.slice!(*(only + force)) if only.present?
    attr.except!(*excp)          if excp.present?

    attr.select! do |k, v|
      error   = ("blank key for #{v.inspect}"      if k.blank?)
      error ||= ("ignoring non-field #{k.inspect}" unless database_columns[k])
      error.blank? or Log.warn("#{__method__}: #{error}")
    end

    # noinspection RubyMismatchedArgumentType
    attr = reject_blanks(attr) if compact
    attr[:options]  = options  if options.present?
    attr[:attr_opt] = opt.merge!(normalized: true)
    attr
  end

  # The fields that will be accepted by #normalize_attributes.
  #
  # @return [Array<Symbol>]
  #
  def allowed_keys
    field_names - [id_column]
  end

  # The fields that will be ignored by #normalize_attributes from a source
  # passed in via the :from parameter.
  #
  # @return [Array<Symbol>]
  #
  def ignored_keys
    [id_column, :created_at, :updated_at]
  end

  # Return with the key name for the given value.
  #
  # @param [String, Symbol] key
  #
  # @return [Symbol]
  #
  def normalize_key(key)
    key_mapping[EnumType.comparable(key)] || key.to_sym
  end

  # A mapping of key comparison value to actual database column name.
  #
  # @return [Hash{String=>Symbol}]
  #
  def key_mapping
    # noinspection RubyMismatchedReturnType
    EnumType.comparable_map(database_columns.keys)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods
    include Record::Assignable
  end

  # Methods which are only appropriate if the including class is an
  # ApplicationRecord.
  #
  module InstanceMethods

    include Record::Assignable

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveRecord::AttributeAssignment
      include Record::Debugging::InstanceMethods
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Model/controller options passed in through the constructor.
    #
    # @return [::Options]
    #
    attr_reader :model_options

    # set_model_options
    #
    # @param [::Options, Hash, nil] options
    #
    # @return [::Options, nil]
    #
    def set_model_options(options)
      options = options[:options]  if options.is_a?(Hash)
      # noinspection RubyMismatchedReturnType
      @model_options = (options.dup if options.is_a?(Options))
    end

    # =========================================================================
    # :section: ActiveRecord overrides
    # =========================================================================

    public

    # Create a new instance.
    #
    # @param [Model, Hash, ActionController::Parameters, nil] attr
    #
    # @return [void]
    #
    # @note - for dev traceability
    #
    def initialize(attr = nil, &block)
      super(attr, &block)
    end

    # Update database fields, including the structured contents of JSON fields.
    #
    # @param [Model, Hash, ActionController::Parameters, nil] attributes
    #
    # @return [void]
    #
    # @see #normalize_attributes
    # @see ActiveModel::AttributeAssignment#assign_attributes
    #
    def assign_attributes(attributes)
      attr = normalize_attributes(attributes)
      opt  = attr.delete(:attr_opt) || {}
      set_model_options(opt[:options])
      super(attr)
    rescue => err # TODO: testing - remove?
      Log.warn { "#{record_name}.#{__method__}: #{err.class}: #{err.message}" }
      raise err
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include InstanceMethods

  end

end

__loading_end(__FILE__)
