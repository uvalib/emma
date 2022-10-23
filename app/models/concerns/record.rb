# app/models/concerns/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for ActiveRecord mixin modules.
#
module Record

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether *base* is a class associated with a database schema.
  #
  # @param [Class, Module, Any] base
  #
  def record_class?(base)
    base.is_a?(Class) && (base <= ApplicationRecord)
  end

  # Indicate whether *base* is a record class which is a model.
  #
  # @param [Class, Module, Any] base
  #
  def model_class?(base)
    record_class?(base) && base.ancestors.include?(Model)
  end

  # Indicate whether the record schema includes any of the given columns.
  #
  # @param [Array<Symbol,String,Array>] columns
  # @param [Boolean]                    any   If *false*, all are required.
  #
  def has_column?(*columns, any: true, **)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Overrides #__included defined in lib/_trace.rb.
  #
  # @param [Module]      base
  # @param [Module]      mod
  # @param [String, nil] tag
  #
  # @return [nil]
  #
  def __included(base, mod, tag = nil)
    tag ||= mod.try(:name)&.remove(/^[^:]+::/) || mod
    super(base, mod, "[#{tag}]")
  end
    .tap { |meth| neutralize(meth) unless TRACE_CONCERNS }

  # Ensure that *mod* is only included in a record class.
  #
  # @param [Class, Module, Any] base
  # @param [Module]             mod
  #
  # @raise [RuntimeError]             If *mod* should not be included in *base*
  #
  # @return [TrueClass]
  #
  # == Usage Notes
  # The assertion is only invoked when running on the desktop.
  #
  def assert_record_class(base, mod)
    return true if base.ancestors.include?(mod) || record_class?(base)
    raise "#{mod}: should not be included by #{base}"
  end
    .tap { |meth| neutralize(meth) if application_deployed? }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # added_modules # TODO: keep?
  #
  # @param [Module]        context    Calling context.
  # @param [Array<Symbol>] original   Original set of constants.
  #
  # @return [Array<Class<Module>>]
  #
  def added_modules(context, original)
    current = context.constants(false)
    # noinspection RubyMismatchedArgumentType
    (current - original).map { |name| context.safe_const_get(name) }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods

    include Record

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveRecord::ModelSchema::ClassMethods
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the record schema includes any of the given columns.
    #
    # @param [Array<Symbol,String,Array>] columns
    # @param [Boolean]                    any   If *false*, all are required.
    #
    def has_column?(*columns, any: true, **)
      any       = true unless any.is_a?(FalseClass)
      total     = column_names.size
      columns   = columns.flatten.compact.map(&:to_s)
      remainder = (column_names - columns).size
      any ? (total > remainder) : (total == (remainder + columns.size))

    rescue ActiveRecord::ActiveRecordError => error
      # There are two cases where this method is allowed to just return *true*
      # rather than raising an exception when the database is not available:
      #
      # * The first is running "rake assets:precompile", which triggers the
      #   "emma:assets:erb" task, which needs to run #js_properties.
      #
      # * The second is only seen from the desktop via "rails runner" for a
      #   single file.
      #
      return true if rake_task? && $*.any? { |arg| arg.include?('assets:') }
      return true if $*.include?('runner')
      raise error
    end

    # Database column schema.
    #
    # @return [Hash{Symbol=>ActiveRecord::ConnectionAdapters::PostgreSQL::Column}]
    #
    def database_columns
      @database_columns ||= columns_hash.symbolize_keys
    end

  end

  # Methods which are only appropriate if the including class is an
  # ApplicationRecord.
  #
  module InstanceMethods

    include Record

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the schema of the current record includes any of the
    # given columns.
    #
    # @param [Array<Symbol,String,Array>] columns
    # @param [Hash]                       opt
    #
    # @see Record::ClassMethods#has_column?
    #
    def has_column?(*columns, **opt)
      self.class.has_column?(*columns, **opt)
    end

    # Database column schema.
    #
    # @return [Hash{Symbol=>ActiveRecord::ConnectionAdapters::PostgreSQL::Column}]
    #
    def database_columns
      self.class.database_columns
    end

    # For use with Record::* methods.
    #
    # @return [Symbol, nil]
    #
    def implicit_order_column
      self.class.implicit_order_column
    end if respond_to?(:implicit_order_column)

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.send(:extend,  self)
    return unless record_class?(base)
    base.send(:include, InstanceMethods)
    base.send(:extend,  ClassMethods)
  end

end

# =============================================================================
# Pre-load record concerns for easier TRACE_LOADING.
# =============================================================================

require_submodules(__FILE__)

__loading_end(__FILE__)
