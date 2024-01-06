# app/helpers/html_helper/attributes.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper HTML support methods.
#
module HtmlHelper::Attributes

  include CssHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # HTML attributes which indicate specification of an accessible name.
  #
  # @type [Array<Symbol>]
  #
  ARIA_LABEL_ATTRS = %i[
    aria-label
    aria-labelledby
    aria-describedby
  ].freeze

  # Indicate whether the HTML element to be created with the given arguments
  # appears to have an accessible name.
  #
  # @param [Array<*>] args
  # @param [Hash]     opt
  #
  def accessible_name?(*args, **opt)
    opt  = args.pop if args.last.is_a?(Hash) && opt.blank?
    name = args.first
    return true if name.present? && (name.html_safe? || !only_symbols?(name))
    return true if opt.slice(:title, *ARIA_LABEL_ATTRS).compact_blank!.present?
    Log.debug { "#{__method__}: none for #{args.inspect} #{opt.inspect}" }
    false
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A line added to tooltips to indicate a .sign-in-required link.
  #
  # @type [String]
  #
  SIGN_IN = I18n.t('emma.download.failure.sign_in').freeze

  # Augment with options that should be set/unset according to the context
  # (e.g. CSS classes present).
  #
  # @param [Symbol, String]  tag
  # @param [Hash{Symbol=>*}] options
  #
  # @return [Hash]
  #
  def add_inferred_attributes(tag, options)
    opt = options.dup
    css = css_class_array(opt[:class])

    # Attribute defaults which may be overridden in *options*.
    css.each do |css_class|
      case css_class.to_sym
        when :hidden    then opt.reverse_merge!('aria-hidden':   true)
        when :disabled  then opt.reverse_merge!('aria-disabled': true)
        when :forbidden then opt.reverse_merge!('aria-disabled': true)
      end
    end

    # Attribute replacements which will override *options*.
    css.each do |css_class|
      case css_class
        when 'sign-in-required'
          if (tip = opt[:title].to_s).blank?
            opt[:title] = SIGN_IN
          elsif !tip.include?(SIGN_IN)
            opt[:title] = tooltip_text(tip, "(#{SIGN_IN})")
          end
      end
    end

    if %w[a button].include?(tag.to_s)
      opt.reverse_merge!(disabled: true) if opt[:'aria-disabled']
    end

    opt[:disabled] ? opt.reverse_merge!('aria-disabled': true) : opt
  end

  # Attributes that are expected for a given HTML tag and can be added
  # automatically.
  #
  # @param[Hash{Symbol=>Hash}]
  #
  # @see https://developer.mozilla.org/en-US/docs/Web/CSS/display#tables
  #
  ADDED_HTML_ATTRIBUTES = {
    button: { type: 'button' },
    table:  { role: 'table' },
    thead:  { role: 'rowgroup' },
    tbody:  { role: 'rowgroup' },
    tfoot:  { role: 'rowgroup' },
    th:     { role: nil },            # Either 'columnheader' or 'rowheader'
    tr:     { role: 'row' },
    td:     { role: nil },            # Either 'cell' or 'gridcell'
  }.deep_freeze

  # Augment with default options.
  #
  # @param [Symbol, String]  tag
  # @param [Hash{Symbol=>*}] options
  #
  # @return [Hash]
  #
  def add_required_attributes(tag, options)
    attrs = ADDED_HTML_ATTRIBUTES[tag&.to_sym]
    attrs&.merge(options) || options
  end

  # Attributes that are expected for a given HTML tag.
  #
  # @param[Hash{Symbol=>Array<Symbol>}]
  #
  REQUIRED_HTML_ATTRIBUTES = {
    table: %i[role aria-rowcount aria-colcount],
    th:    %i[role],
    tr:    %i[role aria-rowindex],
    td:    %i[aria-colindex],
  }.freeze

  # Expected :role values for a given HTML tag.
  #
  # @param[Hash{Symbol=>Array<String>}]
  #
  EXPECTED_ROLES = {
    table: %w[grid table],
    th:    %w[columnheader rowheader],
    td:    %w[cell gridcell],
  }.deep_freeze

  # Verify that options have been included unless 'aria-hidden'.
  #
  # @param [Symbol, String]  tag
  # @param [Hash{Symbol=>*}] options
  # @param [Symbol, nil]     meth     Calling method for diagnostics.
  #
  # @return [Boolean]                 If *false* at least one was missing.
  #
  def check_required_attributes(tag, options, meth: nil)
    return true if true?(options[:'aria-hidden'])
    return true unless REQUIRED_HTML_ATTRIBUTES.include?((tag = tag&.to_sym))
    missing = Array.wrap(REQUIRED_HTML_ATTRIBUTES[tag]) - options.keys
    error   =
      if missing.present?
        'missing attributes: %s' % missing.join(', ')
      elsif (roles = EXPECTED_ROLES[tag]) && !roles.include?(options[:role])
        "unexpected role: #{options[:role]}"
      end
    Log.debug { "#{meth || calling_method}: #{tag}: #{error}" } if error
    error.blank?
  end

end

__loading_end(__FILE__)
