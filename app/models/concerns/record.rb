# app/models/concerns/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'emma/common'
require 'emma/debug'
require 'emma/json'

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
  # @param [Class, *] base
  #
  def record_class?(base)
    base.is_a?(Class) && (base <= ApplicationRecord)
  end

  # Indicate whether *base* is a record class which is a model.
  #
  # @param [Class, *] base
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
  # @param [Class, Module, *] base
  # @param [Module]           mod
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
    rescue ActiveRecord::ConnectionNotEstablished => error
      # Only seen from the desktop via "rails runner" for a single file;
      # in this case only, allow the method to return *true*.
      $*.include?('runner') or raise error
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
      self.class.send(__method__, *columns, **opt)
    end

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