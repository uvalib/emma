# app/helpers/sys_helper/config.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Config

  include SysHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a table current `Rails.configuration` values.
  #
  # @param [Boolean] sort
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to #sys_table.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def application_config(sort: true, css: '.config-table', **opt)
    pairs = rails_config_entries
    pairs.transform_values! { [rails_config_entry(_1)] }
    prepend_css!(opt, css)
    sys_table(pairs, __method__, sort: sort, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Classes whose instances can be directly represented in tables.
  #
  # @type [Array<Class>]
  #
  DIRECT = [
    FalseClass,
    Module,
    NilClass,
    Numeric,
    Range,
    Regexp,
    String,
    Symbol,
    TrueClass,
  ].freeze

  ESCAPE_TEMPLATE = '[=%s=]'
  ESCAPE_REGEXP   = /"\[=([^=\]\n]+)=\]"/.freeze

  # A rendering of a configuration table value.
  #
  # @param [any, nil] val
  # @param [Hash]     opt
  #
  # @option opt [Boolean] :escape     Avoid quote marks around certain values
  # @option opt [Boolean] :inspect    Return inspections of #DIRECT type values
  #
  # @return [any, nil]
  #
  def app_config_entry(val, **opt)
    if opt[:escape]
      case val
        when nil     then return ESCAPE_TEMPLATE % EMPTY_VALUE
        when Symbol  then return ESCAPE_TEMPLATE % val.inspect
        when Regexp  then return ESCAPE_TEMPLATE % val.inspect
        when *DIRECT then # continue below
        when Hash    then # continue below
        when Array   then # continue below
        else              return ESCAPE_TEMPLATE % val.class
      end
    end
    case val
      when nil     then EMPTY_VALUE
      when *DIRECT then opt[:inspect] ? val.inspect : val
      when Hash    then val.transform_values { app_config_entry(_1, **opt) }
      when Array   then val.map { app_config_entry(_1, **opt) }
      else              val.class
    end
  end

  # A rendering of a `Rails.configuration` entry value.
  #
  # @param [any, nil] val
  #
  # @return [String]
  #
  def rails_config_entry(val)
    val = app_config_entry(val, escape: true)
    val = pretty_json(val, log: false)
    val.gsub(ESCAPE_REGEXP, '\1')
  end

  # The current `Rails.configuration` entries.
  #
  # @return [Hash{String=>any,nil}]
  #
  def rails_config_entries
    cfg   = Rails.configuration
    meths = cfg.public_methods(false)
    names = meths.map { _1.to_s.dup.delete_suffix!('=') }.compact
    names.sort.map { [_1, cfg.instance_variable_get(:"@#{_1}")] }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
