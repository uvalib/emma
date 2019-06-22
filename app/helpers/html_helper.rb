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

  # If CSS class name(s) are provided, return a copy of *hash* where the names
  # are append to the existing `hash[:class]` value.  If no CSS class names
  # are provided the original *hash* is returned.
  #
  # @param [Hash]                 opt     The target options hash.
  # @param [Array<String, Array>] args    CSS class names.
  #
  # @return [Hash]
  #
  # @see #css_classes
  #
  # Compare with:
  # @see #prepend_css_classes
  #
  def append_css_classes(opt, *args, &block)
    classes = css_classes(*args, &block).presence
    if opt && classes
      opt.merge(class: css_classes(opt[:class], classes))
    else
      opt || { class: classes }
    end
  end

  # If CSS class name(s) are provided, return a copy of *hash* where the names
  # are prepended to the existing `hash[:class]` value.  If no CSS class names
  # are provided the original *hash* is returned.
  #
  # @param [Hash]                 opt     The target options hash.
  # @param [Array<String, Array>] args    CSS class names.
  #
  # @return [Hash]
  #
  # @see #css_classes
  #
  # Compare with:
  # @see #append_css_classes
  #
  def prepend_css_classes(opt, *args, &block)
    classes = css_classes(*args, &block).presence
    if opt && classes
      opt.merge(class: css_classes(classes, opt[:class]))
    else
      opt || { class: classes }
    end
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
