# app/helpers/css_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper CSS support methods.
#
module CssHelper

  include Emma::Common
  include Emma::Unicode

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the HTML options include any of the given CSS classes.
  #
  # @param [Hash, nil]          html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS classes to find.
  #
  def has_class?(html_opt, *classes)
    classes     = css_class_array(*classes)
    opt_classes = html_opt&.dig(:class) || []
    opt_classes = opt_classes.split(' ') if opt_classes.is_a?(String)
    # noinspection RubyMismatchedArgumentType
    (classes - opt_classes) != classes
  end

  # Combine arrays and space-delimited strings to produce a space-delimited
  # string of CSS class names for use inline.
  #
  # @param [Array<#to_s,Array>] classes
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [classes] Exposes *args* so the block may modify it.
  # @yieldparam  [Array<String>] classes  The initial set of CSS classes.
  # @yieldreturn [void]                   Return ignored.
  #
  def css_classes(*classes, &block)
    css_class_array(*classes, &block).join(' ').html_safe
  end

  # Combine arrays and space-delimited strings to produce set of unique CSS
  # class names.
  #
  # @param [Array<#to_s,Array>] classes
  #
  # @return [Array<String>]
  #
  # @yield [classes] Exposes *args* so the block may modify it.
  # @yieldparam  [Array<String>] classes  The initial set of CSS classes.
  # @yieldreturn [void]                   Return ignored.
  #
  def css_class_array(*classes, &block)
    block.call(classes) if block
    classes.flat_map { |c|
      next if c.blank?
      c.is_a?(Array) ? css_class_array(*c) : c.to_s.squish.split(/[ .]/)
    }.compact_blank.uniq
  end

  # Return a copy of *html_opt* where the classes are appended to the current
  # `html_opt[:class]` value.
  #
  # @param [Hash, String, nil]  html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  # @param [Proc]               block     Passed to #append_css!.
  #
  # @return [Hash]                        A new hash with :class set.
  #
  #--
  # == Variations
  #++
  #
  # @overload append_css(html_opt, *classes, &block)
  #   @param [Hash, String]       html_opt
  #   @param [Array<#to_s,Array>] classes
  #   @param [Proc]               block
  #   @return [Hash]
  #
  # @overload append_css(*classes, &block)
  #   @param [Array<#to_s,Array>] classes
  #   @param [Proc]               block
  #   @return [Hash]
  #
  def append_css(html_opt, *classes, &block)
    if html_opt.nil?
      # Log.debug { "#{__method__}: nil html_opt from #{caller}" }
    elsif !html_opt.is_a?(Hash)
      # noinspection RubyMismatchedArgumentType
      classes.unshift(html_opt)
      html_opt = nil
    end
    html_opt = html_opt&.deep_dup || {}
    append_css!(html_opt, *classes, &block)
  end

  # Replace `html_opt[:class]` with a new string containing the original
  # classes followed by the added classes.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  # @param [Proc]               block     Passed to #css_classes.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  # == Implementation Notes
  # Compare with #prepend_css!
  #
  def append_css!(html_opt, *classes, &block)
    result = css_class_array(html_opt[:class], *classes, &block).join(' ')
    html_opt.merge!(class: result)
  end

  # Return a copy of *html_opt* where the classes are prepended to the current
  # `html_opt[:class]` value.
  #
  # @param [Hash, String, nil]  html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  # @param [Proc]               block     Passed to #prepend_css!
  #
  # @return [Hash]                        A new hash with :class set.
  #
  #--
  # == Variations
  #++
  #
  # @overload prepend_css(html_opt, *classes, &block)
  #   @param [Hash, String]               html_opt
  #   @param [Array<#to_s,Array>] classes
  #   @param [Proc]                       block
  #   @return [Hash]
  #
  # @overload prepend_css(*classes, &block)
  #   @param [Array<#to_s,Array>] classes
  #   @param [Proc]                       block
  #   @return [Hash]
  #
  def prepend_css(html_opt, *classes, &block)
    if html_opt.nil?
      # Log.debug { "#{__method__}: nil html_opt from #{caller}" }
    elsif !html_opt.is_a?(Hash)
      # noinspection RubyMismatchedArgumentType
      classes.unshift(html_opt)
      html_opt = nil
    end
    html_opt = html_opt&.deep_dup || {}
    prepend_css!(html_opt, *classes, &block)
  end

  # Replace `html_opt[:class]` with a new string containing the added classes
  # followed by the original classes.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  # @param [Proc]               block     Passed to #css_classes.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  # == Implementation Notes
  # Compare with #append_css!
  #
  def prepend_css!(html_opt, *classes, &block)
    result = css_class_array(*classes, html_opt[:class], &block).join(' ')
    html_opt.merge!(class: result)
  end

  # Return a copy of *html_opt* where the classes are eliminated from the
  # `html_opt[:class]` value.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  #
  # @return [Hash]                        A new hash with :class set.
  #
  def remove_css(html_opt, *classes)
    Log.debug { "#{__method__}: nil html_opt from #{caller}" } if html_opt.nil?
    html_opt = html_opt&.deep_dup || {}
    remove_css!(html_opt, *classes)
  end

  # Replace `html_opt[:class]` with a new string that includes none of the
  # named classes.  If no classes remain, :class is removed from *html_opt*.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  def remove_css!(html_opt, *classes)
    if (current = css_class_array(html_opt[:class])).blank?
      html_opt.except!(:class)
    elsif (removed = css_class_array(*classes)).blank?
      html_opt
    elsif (result = current - removed).blank?
      html_opt.except!(:class)
    else
      html_opt.merge!(class: css_classes(*result))
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default number of digits produced by #hex_rand.
  #
  # @type [Integer]
  #
  HEX_RAND_DEFAULT_DIGITS = 8

  # Generate a string of random hex digits.
  #
  # @param [Integer] digits           Default: `#HEX_RAND_DEFAULT_DIGITS`
  # @param [Boolean] upper            If *false* show lowercase hex digits.
  #
  # @return [String]
  #
  def hex_rand(digits: nil, upper: nil)
    digits = digits.to_i
    digits = HEX_RAND_DEFAULT_DIGITS unless digits.positive?
    format = "%0#{digits}X"
    format = format.downcase if upper.is_a?(FalseClass)
    limit  = 16.pow(digits) - 1
    format % rand(0..limit)
  end

  # Create a unique CSS identifier from *base* and a random hex digit string.
  #
  # @param [String] base
  #
  # @return [String]
  #
  def css_randomize(base)
    "#{base}-#{hex_rand}"
  end

  # Combine parts into a value for use an an HTML ID of a element associated
  # with a specific search input row.
  #
  # Unless *unique* is *false* or a string, #hex_rand will be used to generate
  # a value to make the resulting ID unique.
  #
  # @param [Array]        parts
  # @param [any, nil]     unique      Value unique to a search unique.
  # @param [Integer, nil] index       Value unique to an input row.
  # @param [Hash]         opt         Passed to #html_id.
  #
  # @return [String]
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def unique_id(*parts, unique: nil, index: nil, **opt)
    unique = hex_rand if unique.nil? || unique.is_a?(TrueClass)
    parts << unique   if unique
    parts << index    if index
    opt.reverse_merge!(underscore: false, camelize: false)
    html_id(*parts, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
