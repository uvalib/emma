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

  # If CSS class name(s) are provided, return a copy of *opt* where the names
  # are appended to the existing `opt[:class]` value.
  #
  # @param [Hash]                 opt     The source options hash.
  # @param [Array<String, Array>] args    CSS class names.
  #
  # @return [Hash]                        A new hash with :class set.
  #
  # @see #append_css_classes!
  #
  def append_css_classes(opt, *args, &block)
    opt = opt&.dup || {}
    append_css_classes!(opt, *args, &block)
  end

  # If CSS class name(s) are provided, append them to the existing
  # `opt[:class]` value.
  #
  # @param [Hash]                 opt     The target options hash.
  # @param [Array<String, Array>] args    CSS class names.
  #
  # @return [Hash]                        The modified *opt* hash.
  #
  # @see #css_classes
  #
  # Compare with:
  # @see #prepend_css_classes!
  #
  def append_css_classes!(opt, *args, &block)
    added  = css_classes(*args, &block)
    result = (current = opt[:class]) ? css_classes(current, added) : added
    opt.merge!(class: result)
  end

  # If CSS class name(s) are provided, return a copy of *opt* where the names
  # are prepended to the existing `opt[:class]` value.
  #
  # @param [Hash]                 opt     The source options hash.
  # @param [Array<String, Array>] args    CSS class names.
  #
  # @return [Hash]                        A new hash with :class set.
  #
  # @see #prepend_css_classes!
  #
  def prepend_css_classes(opt, *args, &block)
    opt = opt&.dup || {}
    prepend_css_classes!(opt, *args, &block)
  end

  # If CSS class name(s) are provided, prepend them to the existing
  # `opt[:class]` value.
  #
  # @param [Hash]                 opt     The target options hash.
  # @param [Array<String, Array>] args    CSS class names.
  #
  # @return [Hash]                        The modified *opt* hash.
  #
  # @see #css_classes
  #
  # Compare with:
  # @see #append_css_classes!
  #
  def prepend_css_classes!(opt, *args, &block)
    added  = css_classes(*args, &block)
    result = (current = opt[:class]) ? css_classes(added, current) : added
    opt.merge!(class: result)
  end

  # Combine arrays and space-delimited strings to produce a space-delimited
  # string of CSS class names for use inline.
  #
  # @param [Array<String, Array>] args
  #
  # @yield [Array<String>]
  # @yieldparam [Array<String>] :classes  The initial set of CSS classes.
  # @yieldreturn [nil]                    The block return is ignored because
  #                                         the block should append to :classes
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

  # Render a camel-case or snake-case string as in "title case" words separated
  # by non-breakable spaces.
  #
  # @param [String, Symbol] text
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def labelize(text)
    words =
      Array.wrap(text)
        .flat_map { |s| s.to_s.split(/[_\s]/) if s.present? }
        .flat_map { |s|
          next if s.blank?
          s = "#{s[0].upcase}#{s[1..-1]}" if s[0] =~ /^[a-z]/
          s.gsub(/[A-Z]+[^A-Z]+/, '\0 ').rstrip.split(' ').map do |word|
            case word
              when 'Id' then 'ID'
              else           word
            end
          end
        }
        .compact
    text = words.join(' ')
    ERB::Util.h(text).gsub(/\s/, '&nbsp;').html_safe
  end

end

__loading_end(__FILE__)
