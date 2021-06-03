# app/helpers/css_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper CSS support methods.
#
module CssHelper

  # @private
  def self.included(base)

    __included(base, 'CssHelper')

    base.send(:extend,  self)

  end

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
  # @param [Proc]               block     Passed to #append_classes!.
  #
  # @return [Hash]                        A new hash with :class set.
  #
  # == Variations
  #
  # @overload append_classes(html_opt, *classes, &block)
  #   @param [Hash, String]       html_opt
  #   @param [Array<#to_s,Array>] classes
  #   @param [Proc]               block
  #   @return [Hash]
  #
  # @overload append_classes(*classes, &block)
  #   @param [Array<#to_s,Array>] classes
  #   @param [Proc]               block
  #   @return [Hash]
  #
  def append_classes(html_opt, *classes, &block)
    if html_opt.nil?
      # Log.debug { "#{__method__}: nil html_opt from #{caller}" }
    elsif !html_opt.is_a?(Hash)
      classes.unshift(html_opt)
      html_opt = nil
    end
    html_opt = html_opt&.dup || {}
    append_classes!(html_opt, *classes, &block)
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
  # Compare with:
  # @see #prepend_classes!
  #
  def append_classes!(html_opt, *classes, &block)
    result = css_class_array(html_opt[:class], *classes, &block).join(' ')
    html_opt.merge!(class: result)
  end

  # Return a copy of *html_opt* where the classes are prepended to the current
  # `html_opt[:class]` value.
  #
  # @param [Hash, String, nil]  html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  # @param [Proc]               block     Passed to #prepend_classes!
  #
  # @return [Hash]                        A new hash with :class set.
  #
  # == Variations
  #
  # @overload prepend_classes(html_opt, *classes, &block)
  #   @param [Hash, String]               html_opt
  #   @param [Array<#to_s,Array>] classes
  #   @param [Proc]                       block
  #   @return [Hash]
  #
  # @overload prepend_classes(*classes, &block)
  #   @param [Array<#to_s,Array>] classes
  #   @param [Proc]                       block
  #   @return [Hash]
  #
  def prepend_classes(html_opt, *classes, &block)
    if html_opt.nil?
      # Log.debug { "#{__method__}: nil html_opt from #{caller}" }
    elsif !html_opt.is_a?(Hash)
      classes.unshift(html_opt)
      html_opt = nil
    end
    html_opt = html_opt&.dup || {}
    prepend_classes!(html_opt, *classes, &block)
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
  # Compare with:
  # @see #append_classes!
  #
  def prepend_classes!(html_opt, *classes, &block)
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
  def remove_classes(html_opt, *classes)
    Log.debug { "#{__method__}: nil html_opt from #{caller}" } if html_opt.nil?
    html_opt = html_opt&.dup || {}
    remove_classes!(html_opt, *classes)
  end

  # Replace `html_opt[:class]` with a new string that includes none of the
  # named classes.  If no classes remain, :class is removed from *html_opt*.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   CSS class names.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  def remove_classes!(html_opt, *classes)
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

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Array<#to_s,Array>] classes
  # @param [Hash]               opt       Internal options:
  #
  # @option opt [String]  :class
  # @option opt [Integer] :row        Grid row (wide screen).
  # @option opt [Integer] :col        Grid column (wide screen).
  # @option opt [Integer] :row_max    Bottom grid row (wide screen).
  # @option opt [Integer] :col_max    Rightmost grid column (wide screen).
  # @option opt [Boolean] :sr_only    If *true*, include 'sr-only' CSS class.
  #
  # @return [Array<String>]
  #
  def grid_cell_classes(*classes, **opt)
    row = positive(opt[:row])
    col = positive(opt[:col])
    classes += Array.wrap(opt[:class])
    classes << "row-#{row}" if row
    classes << "col-#{col}" if col
    classes << 'row-first'  if row == 1
    classes << 'col-first'  if col == 1
    classes << 'row-last'   if row == opt[:row_max].to_i
    classes << 'col-last'   if col == opt[:col_max].to_i
    classes << 'sr-only'    if opt[:sr_only]
    css_class_array(*classes)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       To #append_grid_cell_classes!
  #
  # @return [Hash]                        A new hash.
  #
  def append_grid_cell_classes(html_opt, *classes, **opt)
    Log.debug { "#{__method__}: nil html_opt from #{caller}" } if html_opt.nil?
    html_opt = html_opt&.dup || {}
    append_grid_cell_classes!(html_opt, *classes, **opt)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       Passed to #grid_cell_classes.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  def append_grid_cell_classes!(html_opt, *classes, **opt)
    classes = grid_cell_classes(*classes, **opt)
    append_classes!(html_opt, *classes)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       To #prepend_grid_cell_classes!.
  #
  # @return [Hash]                        A new hash.
  #
  def prepend_grid_cell_classes(html_opt, *classes, **opt)
    Log.debug { "#{__method__}: nil html_opt from #{caller}" } if html_opt.nil?
    html_opt = html_opt&.dup || {}
    prepend_grid_cell_classes!(html_opt, *classes, **opt)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       Passed to #grid_cell_classes.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  def prepend_grid_cell_classes!(html_opt, *classes, **opt)
    classes = grid_cell_classes(*classes, **opt)
    prepend_classes!(html_opt, *classes)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # These are observed hash keys which may travel alongside HTML attributes
  # like :id, :class, :tabindex etc. when passed as named parameters, but
  # should not be passed into methods which actually generate HTML elements.
  #
  # @type [Array<Symbol>]
  #
  NON_HTML_ATTRIBUTES = %i[
    index
    level
    max_index
    min_index
    offset
    skip
  ].freeze

  # Make a copy which has only valid HTML attributes.
  #
  # @param [Hash, nil] html_opt       The target options hash.
  #
  # @return [Hash]
  #
  def html_options(html_opt)
    html_options!(html_opt&.dup || {})
  end

  # Retain only entries which are valid HTML attributes.
  #
  # @param [Hash] html_opt            The target options hash.
  #
  # @return [Hash]                    The modified *html_opt* hash.
  #
  def html_options!(html_opt)
    html_opt.except!(*NON_HTML_ATTRIBUTES)
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
  # @param [Integer] digits
  # @param [Boolean] upper            If *false* show lowercase hex digits.
  #
  # @return [String]
  #
  def hex_rand(digits = nil, upper: nil)
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

end

__loading_end(__FILE__)
