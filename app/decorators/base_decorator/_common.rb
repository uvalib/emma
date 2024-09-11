# app/decorators/base_decorator/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common definitions for modules supporting BaseDecorator.
#
# @!attribute [r] object
#   Set in Draper::Decorator#initialize
#   @return [Model]
#
# @!attribute [r] context
#   Set in Draper::Decorator#initialize
#   @return [Hash]
#
module BaseDecorator::Common

  include Emma::Common
  include Emma::Constants
  include Emma::Unicode
  include Emma::Json
  include Emma::TypeMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # HTML tags indicating construction of a <table>.
  #
  # For use with the :tag named option, any of these tags may be passed in to
  # indicate participation in a table; the method will replace it with the
  # appropriate tag as needed.
  #
  # @type [Array<Symbol>]
  #
  HTML_TABLE_TAGS = %i[table thead tbody th tr td].freeze

  # Indicate whether the given HTML element tag is related to HTML tables.
  #
  # Because of the context in which this method is used, `nil` returns `true`.
  #
  # @param [Symbol, String, nil] tag
  #
  def for_html_table?(tag)
    tag.nil? || HTML_TABLE_TAGS.include?(tag.to_sym)
  end

  # Process a configuration setting to determine whether it indicates a *true*
  # value.
  #
  # @param [any, nil] value
  # @param [Boolean]  default         Returned if *value* is *nil*.
  #
  # @return [Boolean]
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def check_setting(value, default: true)
    case value
      when nil    then default
      when Hash   then Log.debug { "#{__method__}: ignored #{value.inspect}" }
      when Array  then value.presence&.all? { check_setting(_1) }
      when Symbol then respond_to?(value) ? send(value) : object.try(value)
      when Proc   then value.call(object)
      else             true?(value)
    end || false
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce a copy of *opt* with 'data-trace-*' attributes.
  #
  # @param [Hash, nil]   opt
  # @param [Symbol, nil] meth         Default: #calling_method.
  #
  # @return [Hash]                    Empty if `DEBUG_ATTRS` is *false*.
  #
  def trace_attrs(opt = nil, meth = nil)
    opt    = opt&.dup || {}
    meth ||= calling_method
    # noinspection RubyMismatchedArgumentType
    trace_attrs!(opt, meth)
  end
    .tap { define_method(_1) { |opt, *| opt&.dup || {} } unless DEBUG_ATTRS }

  # Inject 'data-trace-*' attributes into *opt*.
  #
  # @param [Hash]        opt
  # @param [Symbol, nil] meth         Default: #calling_method.
  # @param [String]      separator    Chain item delimiter.
  #
  # @return [Hash]                    The modified *opt*.
  #
  def trace_attrs!(opt, meth = nil, separator: ",\n")
    meth  = (meth || calling_method).to_s
    from  = opt[:'data-trace-method'] || meth
    chain = opt[:'data-trace-chain']&.split(separator) || []
    chain.pop if chain.last == meth
    opt[:'data-trace-class'] ||= self.class.name
    opt[:'data-trace-chain']   = (chain << meth).join(separator)
    opt[:'data-trace-caller']  = from
    opt[:'data-trace-method']  = meth
    opt
  end
    .tap { define_method(_1) { |opt, *, **| opt } unless DEBUG_ATTRS }

  # Extract 'data-trace-*' attributes from *opt*.
  #
  # @param [Hash]          opt
  # @param [Array<Symbol>] skip
  #
  # @return [Hash]                    Empty if `DEBUG_ATTRS` is *false*.
  #
  def trace_attrs_from(opt, skip: %i[data-trace-method])
    opt.except(*skip).select { |k, _| k.start_with?('data-trace-') }
  end
    .tap { define_method(_1) { |*, **| Hash.new } unless DEBUG_ATTRS }

end

__loading_end(__FILE__)
