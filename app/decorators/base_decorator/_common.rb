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
#   @return [Hash{Symbol=>*}]
#
module BaseDecorator::Common

  include Emma::Common
  include Emma::Constants
  include Emma::Unicode
  include Emma::Json

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
    .tap { |m| define_method(m) { |opt,*| opt&.dup || {} } unless DEBUG_ATTRS }

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
    opt.merge!('data-trace-method': meth)
  end
    .tap { |meth| define_method(meth) { |opt, *, **| opt } unless DEBUG_ATTRS }

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
    .tap { |meth| define_method(meth) { |*, **| Hash.new } unless DEBUG_ATTRS }

end

__loading_end(__FILE__)
