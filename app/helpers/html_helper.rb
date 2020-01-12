# app/helpers/html_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared HTML support methods.
#
module HtmlHelper

  def self.included(base)
    __included(base, '[HtmlHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the HTML options include any of the given CSS classes.
  #
  # @param [Hash, nil]     opt        The target options hash.
  # @param [Array<String>] classes    CSS classes to find.
  #
  def has_class?(opt, *classes)
    opt_classes = opt&.dig(:class)
    opt_classes = opt_classes.to_s.split(' ') if opt_classes.is_a?(String)
    Array.wrap(opt_classes).any? { |c| classes.include?(c) }
  end

  # Merge values from one or more options hashes.
  #
  # @param [Hash, nil]   opt          The target options hash.
  # @param [Array<Hash>] args         Options hash(es) to merge into *opt*.
  #
  # @return [Hash]                    A new hash.
  #
  # @see #merge_html_options!
  #
  def merge_html_options(opt, *args)
    merge_html_options!(opt&.dup, *args)
  end

  # Merge values from one or more hashes into an options hash.
  #
  # @param [Hash, nil]   opt          The target options hash.
  # @param [Array<Hash>] args         Options hash(es) to merge into *opt*.
  #
  # @return [Hash]                    The modified *opt* hash.
  #
  # @see #append_css_classes!
  #
  def merge_html_options!(opt, *args)
    opt ||= {}
    args.each do |arg|
      next unless arg.is_a?(Hash)
      opt.merge!(arg.except(:class))
      append_css_classes!(opt, arg[:class])
    end
    opt
  end

  # If CSS class name(s) are provided, return a copy of *opt* where the names
  # are appended to the existing `opt[:class]` value.
  #
  # @param [Hash, nil]           opt    The source options hash (if present).
  # @param [Array<String,Array>] args   CSS class names.
  # @param [Proc]                block  Passed to #append_css_classes!.
  #
  # @return [Hash]                      A new hash with :class set.
  #
  def append_css_classes(opt, *args, &block)
    if opt && !opt.is_a?(Hash)
      args.unshift(opt)
      opt = nil
    end
    append_css_classes!(opt&.dup, *args, &block)
  end

  # If CSS class name(s) are provided, append them to the existing
  # `opt[:class]` value.
  #
  # @param [Hash, nil]           opt    The target options hash.
  # @param [Array<String,Array>] args   CSS class names.
  # @param [Proc]                block  Passed to #css_classes.
  #
  # @return [Hash]                      The modified *opt* hash.
  #
  # Compare with:
  # @see #prepend_css_classes!
  #
  def append_css_classes!(opt, *args, &block)
    opt  ||= {}
    added  = css_classes(*args, &block)
    result = (current = opt[:class]) ? css_classes(current, added) : added
    opt.merge!(class: result)
  end

  # If CSS class name(s) are provided, return a copy of *opt* where the names
  # are prepended to the existing `opt[:class]` value.
  #
  # @param [Hash, nil]           opt    The source options hash (if present).
  # @param [Array<String,Array>] args   CSS class names.
  # @param [Proc]                block  Passed to #prepend_css_classes!.
  #
  # @return [Hash]                      A new hash with :class set.
  #
  def prepend_css_classes(opt, *args, &block)
    if opt && !opt.is_a?(Hash)
      args.unshift(opt)
      opt = nil
    end
    prepend_css_classes!(opt&.dup, *args, &block)
  end

  # If CSS class name(s) are provided, prepend them to the existing
  # `opt[:class]` value.
  #
  # @param [Hash, nil]           opt    The target options hash.
  # @param [Array<String,Array>] args   CSS class names.
  # @param [Proc]                block  Passed to #css_classes.
  #
  # @return [Hash]                      The modified *opt* hash.
  #
  # Compare with:
  # @see #append_css_classes!
  #
  def prepend_css_classes!(opt, *args, &block)
    opt  ||= {}
    added  = css_classes(*args, &block)
    result = (current = opt[:class]) ? css_classes(added, current) : added
    opt.merge!(class: result)
  end

  # Combine arrays and space-delimited strings to produce a space-delimited
  # string of CSS class names for use inline.
  #
  # @yield [classes] Exposes *args* so the block may modify it.
  # @yieldparam  [Array<String>] classes  The initial set of CSS classes.
  # @yieldreturn [void]                   Return ignored.
  #
  # @param [Array<String,Array>] args
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def css_classes(*args)
    yield(args) if block_given?
    args.flat_map { |a|
      a.is_a?(Array) ? a : a.to_s.squish.split(' ') if a.present?
    }.compact.uniq.join(' ').html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce a link with appropriate accessibility settings.
  #
  # @param [String] label
  # @param [String] path
  # @param [Hash]   opt               Passed to #link_to.
  # @param [Proc]   block             Passed to #link_to.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Usage Notes
  # This method assumes that local paths are always relative.
  #
  def make_link(label, path, **opt, &block)
    if opt[:target] == '_blank'
      opt[:title] &&= "#{opt[:title]}\n(opens in a new window)" # TODO: I18n
      opt[:title] ||= '(Opens in a new window.)'                # TODO: I18n
    end
    unless opt.key?(:rel)
      opt[:rel] = 'noopener' if path.start_with?('http')
    end
    unless opt.key?(:tabindex)
      opt[:tabindex] = -1 if opt[:'aria-hidden'] || has_class?(opt, 'disabled')
    end
    unless opt.key?(:'aria-hidden')
      opt[:'aria-hidden'] = true if opt[:tabindex] == -1
    end
    link_to(label, path, opt, &block)
  end

end

__loading_end(__FILE__)
