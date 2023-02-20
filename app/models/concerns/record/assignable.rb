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

  # Option parameters for #attribute_options:
  #
  # * :from     A record used to provide initial field values.
  # * :user     Transformed into a :user_id value.
  # * :force    Allow these fields unconditionally.
  # * :except   Ignore these fields (default: []).
  # * :only     Not limited if *false* (default: `#field_name`).
  # * :compact  If *false*, allow blanks (default: *true*).
  # * :key_norm If *true*, transform provided keys to the real column name.
  # * :options  An Options instance.
  #
  ATTRIBUTE_OPTIONS_OPTS =
    %i[from user force except only compact key_norm options].freeze

  # Called to prepare values to be used for assignment to record attributes.
  #
  # @param [Hash, ActionController::Parameters, Model, nil] attr
  # @param [Hash, nil] opt      Added pairs except for #ATTRIBUTE_OPTIONS_OPTS:
  #
  # @option attr [ApplicationRecord]            :from
  # @option attr [User, String, Integer]        :user
  # @option attr [Symbol, Array<Symbol>]        :force
  # @option attr [Symbol, Array<Symbol>]        :except
  # @option attr [Symbol, Array<Symbol>, false] :only
  # @option attr [Boolean]                      :compact
  # @option attr [Boolean]                      :key_norm
  #
  # @raise [RuntimeError]             If the type of *attr* is invalid.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def attribute_options(attr, opt = nil)
    return {} if attr.blank?

    if attr.is_a?(ApplicationRecord)
      unless attr.is_a?(record_class)
        Log.warn { "#{record_class}: assigning from a #{attr.class} record" }
      end
      attr = attr.fields.except!(*ignored_keys)
    else
      attr = attr.dup         if attr.is_a?(Hash)
      attr = attr.params      if attr.respond_to?(:params)
      attr = attr.to_unsafe_h if attr.respond_to?(:to_unsafe_h)
      raise "#{attr.class}: unexpected" unless attr.is_a?(Hash)
    end

    opt, added = partition_hash(opt, *ATTRIBUTE_OPTIONS_OPTS)

    from    = opt[:from] && attribute_options(opt[:from], except: ignored_keys)
    user    = from&.extract!(:user, :user_id)&.compact&.values&.first
    user    = attr.extract!(:user, :user_id).compact.values.first || user
    user    = opt.extract!(:user, :user_id).compact.values.first || user
    force   = Array.wrap(opt[:force])
    excp    = Array.wrap(opt[:except]) - force
    only    = !false?(opt[:only]) && Array.wrap(opt[:only] || allowed_keys)
    compact = !false?(opt[:compact])
    options = [opt[:options], from&.delete(:options)].compact.first

    attr.reverse_merge!(from)     if from.present?
    attr.merge!(added)            if added.present?

    attr.transform_keys! { |k| k.to_s.delete_suffix('[]').to_sym }
    attr.transform_keys! { |k| normalize_key(k) } if true?(opt[:key_norm])

    attr.merge!(user_id: user)    if (user &&= User.id_value(user))
    attr.slice!(*(only + force))  if only.present?
    attr.except!(*excp)           if excp.present?

    attr.select! do |k, v|
      error   = ("blank key for #{v.inspect}"      if k.blank?)
      error ||= ("ignoring non-field #{k.inspect}" unless database_columns[k])
      error.blank? or Log.warn("#{__method__}: #{error}")
    end
    attr.merge!(options: options) if options.present?

    # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
    compact ? reject_blanks(attr) : attr
  end

  # The fields that will be accepted by #attribute_options.
  #
  # @return [Array<Symbol>]
  #
  def allowed_keys
    field_names - [id_column]
  end

  # The fields that will be ignored by #attribute_options from a source
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
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Model/controller options passed in through the constructor.
    #
    # @return [Entry::Options]
    #
    attr_reader :model_options

    # set_model_options
    #
    # @param [Entry::Options, Hash, nil] options
    #
    # @return [Entry::Options, nil]
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

    # Update database fields, including the structured contents of JSON fields.
    #
    # @param [Hash, ActionController::Parameters, Model, nil] attr
    # @param [Hash, nil]                                      opt
    #
    # @return [void]
    #
    # @see #attribute_options
    # @see ActiveModel::AttributeAssignment#assign_attributes
    #
    def assign_attributes(attr, opt = nil)
      attr = attribute_options(attr, opt)
      set_model_options(attr&.delete(:options))
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
