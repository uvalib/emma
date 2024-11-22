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

  extend self

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
    classes = css_class_array(*classes)
    opt_cls = css_class_array(*html_opt&.dig(:class))
    opt_cls.intersect?(classes)
  end

  # Combine arrays and space-delimited strings to produce a space-delimited
  # string of CSS class names for use inline.
  #
  # @param [Array<#to_s,Array>] classes
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def css_classes(*classes)
    css_class_array(*classes).join(' ').html_safe
  end

  # Combine arrays and space-delimited strings to produce set of unique CSS
  # class names.
  #
  # @param [Array<#to_s,Array>] classes
  #
  # @return [Array<String>]
  #
  def css_class_array(*classes)
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
  #
  # @return [Hash]                        A new hash with :class set.
  #
  #--
  # === Variations
  #++
  #
  # @overload append_css(html_opt, *classes)
  #   @param [Hash, String]       html_opt
  #   @param [Array<#to_s,Array>] classes
  #   @return [Hash]
  #
  # @overload append_css(*classes)
  #   @param [Array<#to_s,Array>] classes
  #   @return [Hash]
  #
  def append_css(html_opt, *classes)
    # noinspection RubyMismatchedArgumentType
    if html_opt.is_a?(Hash)
      html_opt = dup_options(html_opt)
      append_css!(html_opt, *classes)
    else
      classes.unshift(html_opt) if html_opt.present?
      append_css!({}, *classes)
    end
  end

  # Replace `html_opt[:class]` with a new string containing the original
  # classes followed by the added classes.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  # === Implementation Notes
  # Compare with #prepend_css!
  #
  def append_css!(html_opt, *classes)
    result = css_classes(*html_opt[:class], *classes)
    html_opt.merge!(class: result)
  end

  # Return a copy of *html_opt* where the classes are prepended to the current
  # `html_opt[:class]` value.
  #
  # @param [Hash, String, nil]  html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  #
  # @return [Hash]                        A new hash with :class set.
  #
  #--
  # === Variations
  #++
  #
  # @overload prepend_css(html_opt, *classes)
  #   @param [Hash, String]       html_opt
  #   @param [Array<#to_s,Array>] classes
  #   @return [Hash]
  #
  # @overload prepend_css(*classes)
  #   @param [Array<#to_s,Array>] classes
  #   @return [Hash]
  #
  def prepend_css(html_opt, *classes)
    # noinspection RubyMismatchedArgumentType
    if html_opt.is_a?(Hash)
      html_opt = dup_options(html_opt)
      prepend_css!(html_opt, *classes)
    else
      classes.unshift(html_opt) if html_opt.present?
      prepend_css!({}, *classes)
    end
  end

  # Replace `html_opt[:class]` with a new string containing the added classes
  # followed by the original classes.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  # === Implementation Notes
  # Compare with #append_css!
  #
  def prepend_css!(html_opt, *classes)
    result = css_classes(*classes, *html_opt[:class])
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
  # @note Currently unused.
  # :nocov:
  def remove_css(html_opt, *classes, &blk)
    if html_opt.is_a?(Hash)
      html_opt = dup_options(html_opt)
      remove_css!(html_opt, *classes, &blk)
    else
      Log.debug { "#{__method__}: nil html_opt from #{calling_method}" }
      {}
    end
  end
  # :nocov:

  # Replace `html_opt[:class]` with a new string that includes none of the
  # named classes.  If no classes remain, :class is removed from *html_opt*.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  # @yield [cls] Indicate whether a CSS class should be removed.
  # @yieldparam [String] cls          A current *html_opt* CSS class.
  # @yieldreturn [any, nil]           Truthy if `*cls*` should be removed.
  #
  def remove_css!(html_opt, *classes, &blk)
    current = css_class_array(*html_opt[:class]).presence
    classes = current && css_class_array(*classes)
    classes&.concat(current.select(&blk)) if blk
    removed = current && (current - classes).presence
    case
      when removed then html_opt.merge!(class: removed.join(' ').html_safe)
      when classes then html_opt.except!(:class)
      else              html_opt
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return an independent copy of HTML options that can be modified without
  # affecting the original.
  #
  # @param [Hash, nil] html_opt
  #
  # @return [Hash]
  #
  def dup_options(html_opt)
    # noinspection RubyMismatchedReturnType
    html_opt.presence ? deep_dup_options(html_opt) : {}
  end

  # Recursively duplicate HTML options parts, avoiding duplication of object
  # instances and other things that may be passed via named options.
  #
  # @param [any, nil] item
  #
  # @return [any, nil]
  #
  def deep_dup_options(item)
    case item
      when *NO_DUP then item
      when String  then item.dup
      when Array   then item.map { deep_dup_options(_1) }
      when Hash    then item.transform_values { deep_dup_options(_1) }
      else              duplicable_option?(item) ? item.dup : item
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @private
  NO_DUP = [NilClass, BoolType, Numeric, Symbol, Method, Module, Proc].freeze

  # Indicate whether the item should be duplicated as part of a deep_dup of
  # HTML options.
  #
  # @param [any, nil] item
  #
  def duplicable_option?(item)
    case item
      when Model, Record, *NO_DUP   then false
      when AbstractController::Base then false
      when ActiveRecord::Base       then false
      when ActiveJob::Base          then false
      else                               item.duplicable?
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
  HEX_RAND_DIGITS = ENV_VAR['HEX_RAND_DIGITS'].to_i

  # Generate a string of random hex digits.
  #
  # @param [Integer] digits           Default: `#HEX_RAND_DIGITS`
  # @param [Boolean] upper            If *false* show lowercase hex digits.
  #
  # @return [String]
  #
  def hex_rand(digits: nil, upper: nil)
    digits = positive(digits) || HEX_RAND_DIGITS
    limit  = 16.pow(digits) - 1
    value  = rand(0..limit)
    hex_format(value, digits: digits, upper: upper)
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

  # Combine parts into a value for use as an HTML ID of an element associated
  # with a specific search input row.
  #
  # Unless *unique* is *false* or a string, #hex_rand will be used to generate
  # a value to make the resulting ID unique.
  #
  # @param [Array<*>]     parts
  # @param [any, nil]     unique      Value unique to a search unique.
  # @param [Integer, nil] index       Value unique to an input row.
  # @param [Hash]         opt         Passed to #html_id.
  #
  # @return [String]
  #
  def unique_id(*parts, unique: nil, index: nil, **opt)
    unique = hex_rand if unique.nil? || unique.is_a?(TrueClass)
    html_id(*parts, unique, index, underscore: false, camelize: false, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
