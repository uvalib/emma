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

  # The key for a hash value used to pass internal-use information alongside
  # HTML attributes.
  #
  # If the key is :internal then the associated value should be a Hash.
  # If the key starts with "internal" (e.g. :internal_xxx or :"internal-xxx")
  # then the associated value may be anything.
  #
  # @type [Symbol]
  #
  INTERNAL_ATTR = :internal

  # @private
  # @type [Regexp]
  INTERNAL_ATTR_RE = /^#{INTERNAL_ATTR}([_-]|$)/i.freeze

  # Indicate whether the given key is an internal attribute.
  #
  # @param [Symbol, String, nil] key
  #
  def internal_attribute?(key)
    key&.match?(INTERNAL_ATTR_RE) || false
  end

  # These are observed hash keys which may travel alongside HTML attributes
  # like :id, :class, :tabindex etc. when passed as named parameters, but
  # should not be passed into methods which actually generate HTML elements.
  #
  # @type [Array<Symbol>]
  #
  NON_HTML_ATTRIBUTES = %i[
    index
    level
    offset
    row
    skip
  ].push(INTERNAL_ATTR).freeze

  # Remove hash keys which are definitely not HTML attributes.
  #
  # @param [Hash] html_opt
  #
  # @return [Hash]                    The modified *html_opt* hash.
  #
  def remove_non_attributes!(html_opt)
    html_opt.reject! { |k, _| k.nil? || internal_attribute?(k) }
    html_opt.except!(*NON_HTML_ATTRIBUTES)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Augment with attributes that should be set/unset according to the context
  # (e.g. CSS classes present).
  #
  # @param [Symbol, String] tag
  # @param [Hash]           opt
  #
  # @return [Hash]          The possibly-modified *opt*.
  #
  def add_inferred_attributes!(tag, opt)
    cls      = css_class_array(opt[:class])
    default  = {} # Attribute defaults which may be overridden in *opt*.
    new_attr = {} # Attribute replacements which will override *opt*.

    # Establish default attribute values.
    default[:'aria-disabled'] = true if cls.intersect?(%w[disabled forbidden])
    default[:'aria-hidden']   = true if cls.include?('hidden')

    # Mark up tooltip with a condition message if needed.
    if (forbid = opt[:'data-forbid'])
      # Already includes a custom failure condition message.
    elsif cls.include?('role-failure')
      forbid = config_page(:download, :failure, :role_failure)
    elsif cls.include?('sign-in-required')
      forbid = config_page(:download, :failure, :sign_in)
    end
    if forbid
      if (tip = opt[:title].to_s).blank?
        new_attr[:title] = forbid
      elsif !tip.include?(forbid)
        new_attr[:title] = tooltip_text(tip, "(#{forbid})")
      end
      new_attr[:'data-forbid'] = forbid unless opt.key?(:'data-forbid')
    end

    default.merge!(opt, new_attr)
    opt.reverse_merge!(default).merge!(new_attr).tap do |result|
      if %w[a button].include?(tag.to_s) && result[:'aria-disabled']
        result[:disabled] = true unless result.key?(:disabled)
      end
      if result[:disabled]
        result[:'aria-disabled'] = true unless result.key?(:'aria-disabled')
      end
    end
  end

  # Attributes that are expected for a given HTML tag and can be added
  # automatically.
  #
  # @type [Hash{Symbol=>Hash}]
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

  # Augment with default attributes.
  #
  # @param [Symbol, String] tag
  # @param [Hash]           opt
  #
  # @return [Hash]          The possibly-modified *opt*.
  #
  def add_required_attributes!(tag, opt)
    attrs = ADDED_HTML_ATTRIBUTES[tag&.to_sym] || {}
    opt.reverse_merge!(attrs)
  end

  # Attributes that are expected for a given HTML tag.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  REQUIRED_HTML_ATTRIBUTES = {
    table: %i[role aria-rowcount aria-colcount],
    th:    %i[role],
    tr:    %i[role aria-rowindex],
    td:    %i[aria-colindex],
  }.deep_freeze

  # Expected :role values for a given HTML tag.
  #
  # @type [Hash{Symbol=>Array<String>}]
  #
  EXPECTED_ROLES = {
    table: %w[grid table],
    th:    %w[columnheader rowheader],
    td:    %w[cell gridcell],
  }.deep_freeze

  # Verify that options have been included unless 'aria-hidden'.
  #
  # @param [Symbol, String] tag
  # @param [Hash]           opt
  # @param [Symbol, nil]    meth      Calling method for diagnostics.
  #
  # @return [Boolean]                 If *false* at least one was missing.
  #
  def check_required_attributes(tag, opt, meth: nil)
    return true if true?(opt[:'aria-hidden'])
    return true unless REQUIRED_HTML_ATTRIBUTES.include?((tag = tag&.to_sym))
    missing = Array.wrap(REQUIRED_HTML_ATTRIBUTES[tag]) - opt.keys
    error   =
      if missing.present?
        'missing attributes: %s' % missing.join(', ')
      elsif (roles = EXPECTED_ROLES[tag]) && !roles.include?(opt[:role])
        "unexpected role: #{opt[:role]}"
      end
    Log.debug { "#{meth || calling_method}: #{tag}: #{error}" } if error
    error.blank?
  end

end

__loading_end(__FILE__)
