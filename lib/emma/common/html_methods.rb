# lib/emma/common/html_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'erb'
require 'emma/common/string_methods'

module Emma::Common::HtmlMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # ASCII characters.
  #
  # @type [String]
  #
  ASCII = (1..255).map(&:chr).join.freeze

  # Work break characters (for use with #tr or #delete). Sequences of any of
  # these in #html_id will be replaced by a single separator character.
  #
  # @type [String]
  #
  HTML_ID_WORD_BREAK = (ASCII.remove(/[[:graph:]]/) << '._\-').freeze

  # Characters (for use with #tr or #delete) that are ignored by #html_id.
  #
  # @type [String]
  #
  HTML_ID_IGNORED = ASCII.remove(/[^[:punct:]]/).freeze

  # HTML break element.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  HTML_BREAK = "<br/>\n".html_safe.freeze

  # HTML non-breaking space.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  HTML_SPACE = '&nbsp;'.html_safe.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Combine parts into a value safe for use as an HTML ID (or class name).
  #
  # A 'Z' is prepended if the result would not have started with a letter.
  #
  # @param [Array]   parts
  # @param [String]  separator        Separator between parts.
  # @param [Boolean] underscore
  # @param [Boolean] camelize         Replace underscores with caps.
  #
  # @return [String]
  #
  def html_id(*parts, separator: '-', underscore: true, camelize: false, **)
    separator  = '' if separator.blank?
    word_break = HTML_ID_WORD_BREAK + separator
    ignored    = HTML_ID_IGNORED.delete(separator)
    parts.map { |part|
      next if part.blank?
      part = sanitized_string(part) if part.is_a?(ActiveSupport::SafeBuffer)
      part = part.to_s
      part = part.tr_s(word_break, ' ').strip.tr(' ', separator)
      part = part.delete(ignored)
      part = part.underscore if underscore || camelize
      part = part.camelize   if camelize
      part.presence
    }.compact.join(separator).tap { |result|
      # noinspection RubyResolve
      result.prepend('Z') unless result.start_with?(/[a-z]/i)
    }
  end

  # Combine an array containing a mix of items into an HTML-safe result.
  #
  # @param [Array, *]    items
  # @param [String, nil] separator
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [array] To supply additional content elements.
  # @yieldparam  [Array<String>] array
  # @yieldreturn [Array<String>, String, nil]
  #
  # === Usage Notes
  # This is basically ActionView::Helpers::OutputSafetyHelper#safe_join but
  # without the dependence on Rails.
  #
  def html_join(items, separator = nil)
    sep   = separator ? ERB::Util.unwrapped_html_escape(separator) : ''
    array = items.is_a?(Array) ? items.flatten : Array.wrap(items)
    added = (yield(array) if block_given?)
    array.concat(Array.wrap(added)) unless added.nil? || added.equal?(array)
    array.map! { |v| ERB::Util.unwrapped_html_escape(v) }.join(sep).html_safe
  end

end

__loading_end(__FILE__)
