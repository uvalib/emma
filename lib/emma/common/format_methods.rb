# lib/emma/common/format_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'erb'

module Emma::Common::FormatMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<Symbol>]
  INFLECT_SINGULAR = %i[single singular singularize].freeze

  # @type [Array<Symbol>]
  INFLECT_PLURAL = %i[plural pluralize].freeze

  # Pluralize or singularize *text*.  If neither *inflection* nor *count* is
  # specified then a copy of the original string is returned.
  #
  # @param [ActiveSupport::SafeBuffer, String] text
  # @param [Integer, nil]                      count
  # @param [Symbol, nil]                       inflect
  #
  # @return [ActiveSupport::SafeBuffer, String]
  #
  # @see #INFLECT_SINGULAR
  # @see #INFLECT_PLURAL
  #
  def inflection(text, count = nil, inflect: nil)
    if (count == 1) || INFLECT_SINGULAR.include?(inflect)
      text.to_s.singularize
    elsif count.is_a?(Integer) || INFLECT_PLURAL.include?(inflect)
      text.to_s.pluralize
    else
      text.to_s.dup
    end
  end

  # Render text that will not break on word boundaries.
  #
  # @param [String, nil] text
  # @param [Boolean]     force        If *true* then the translation will
  #                                     happen even if text.html_safe?.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def non_breaking(text, force: false)
    text ||= ''
    text = ERB::Util.h(text) unless (safe = text.html_safe?)
    text = text.gsub(/[ \t]/, '&nbsp;').html_safe if force || !safe
    # noinspection RubyMismatchedReturnType
    text
  end

  # Render a camel-case or snake-case string as in "title case" words separated
  # by non-breakable spaces.
  #
  # If *text* is already HTML-ready it is returned directly.
  #
  # @param [String, Symbol, nil]  text
  # @param [Integer, nil]         count       Passed to #inflection.
  # @param [Boolean]              breakable   If *false* replace spaces with
  #                                             '&nbsp;' so that the result is
  #                                             not word-breakable.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def labelize(text, count = nil, breakable: true)
    # noinspection RubyMismatchedReturnType
    return text if text.is_a?(ActiveSupport::SafeBuffer)
    result =
      Array.wrap(text)
        .flat_map { |s| s.to_s.split(/[_\s]/) if s.present? }
        .flat_map { |s|
          next if s.blank?
          s = s.upcase_first.gsub(/[A-Z]+[^A-Z]+/, '\0 ').rstrip
          s.split(' ').map { |word| (word == 'Id') ? word.upcase : word }
        }.compact.join(' ')
    result = inflection(result, count) if count
    result = non_breaking(result)      unless breakable
    ERB::Util.h(result)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<String>]
  QUOTE_MARKS = %w( ' " ).freeze

  # @type [Array<ActiveSupport::SafeBuffer>]
  HTML_QUOTES = QUOTE_MARKS.map { |q| ERB::Util.h(q) }.deep_freeze

  # Add surrounding quotation marks to a term.
  #
  # If the term is already quoted, those quotation marks are preserved.
  #
  # @param [ActiveSupport::SafeBuffer, String, Array] term
  # @param [String]                                   quote
  # @param [String]                                   separator
  #
  # @return [ActiveSupport::SafeBuffer, String, Array]
  #
  #--
  # == Variations
  #++
  #
  # @overload quote(term, quote: '"', separator: ', ')
  #   @param [String] term
  #   @param [String] quote
  #   @param [String] separator
  #   @return [String]
  #
  # @overload quote(terms, quote: '"', separator: ', ')
  #   @param [Array<String>] terms
  #   @param [String]        quote
  #   @param [String]        separator
  #   @return [String]
  #
  # @overload quote(term, quote: '"', separator: ', ')
  #   @param [ActiveSupport::SafeBuffer] term
  #   @param [String]                quote
  #   @param [String]                separator
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload quote(terms, quote: '"', separator: ', ')
  #   @param [Array<ActiveSupport::SafeBuffer>] terms
  #   @param [String]                       quote
  #   @param [String]                       separator
  #   @return [ActiveSupport::SafeBuffer]
  #
  def quote(term, quote: '"', separator: ', ')
    if term.is_a?(Array)
      terms = term.map { |t| quote(t, quote: quote, separator: separator) }
      html  = terms.all?(&:html_safe?)
      html ? html_join(terms, separator) : terms.join(separator)

    elsif !term.is_a?(String)
      "#{quote}#{term}#{quote}"

    elsif term.html_safe?
      quote  = ERB::Util.h(quote)
      quotes = [*HTML_QUOTES, quote].uniq
      quoted = quotes.any? { |q| term.start_with?(q) && term.end_with?(q) }
      quoted ? term : "#{quote}#{term}#{quote}".html_safe

    else
      term   = term.strip
      quotes = [*QUOTE_MARKS, quote].uniq
      quoted = quotes.any? { |q| term.start_with?(q) && term.end_with?(q) }
      quoted ? term : "#{quote}#{term}#{quote}"
    end
  end

  # Remove pairs of surrounding quotation marks from a term.
  #
  # @param [ActiveSupport::SafeBuffer, String, Array] term
  # @param [String]                                   separator
  #
  # @return [ActiveSupport::SafeBuffer, String, Array]
  #
  #--
  # == Variations
  #++
  #
  # @overload strip_quotes(term, separator: ', ')
  #   @param [String] term
  #   @param [String] separator
  #   @return [String]
  #
  # @overload strip_quotes(terms, separator: ', ')
  #   @param [Array<String>] terms
  #   @param [String]        separator
  #   @return [String]
  #
  # @overload strip_quotes(term, separator: ', ')
  #   @param [ActiveSupport::SafeBuffer] term
  #   @param [String]                separator
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload strip_quotes(terms, separator: ', ')
  #   @param [Array<ActiveSupport::SafeBuffer>] terms
  #   @param [String]                       separator
  #   @return [ActiveSupport::SafeBuffer]
  #
  def strip_quotes(term, separator: ', ')
    if term.is_a?(Array)
      terms = term.map { |t| strip_quotes(t, separator: separator) }
      html  = terms.all?(&:html_safe?)
      html ? html_join(terms, separator) : terms.join(separator)
    elsif !term.is_a?(String)
      term.to_s
    elsif term.html_safe?
      quote = HTML_QUOTES.find { |q| term.start_with?(q) && term.end_with?(q) }
      quote ? term.delete_prefix(quote).delete_suffix(quote).html_safe : term
    else
      term  = term.to_s.strip
      quote = QUOTE_MARKS.find { |q| term.start_with?(q) && term.end_with?(q) }
      quote ? term.delete_prefix(quote).delete_suffix(quote) : term
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Match a named reference like "%{name}" for a #sprintf argument.
  #
  # @type [Regexp]
  #
  SPRINTF_NAMED_REFERENCE = /%{([^}]+)}/.freeze

  # Match a formatted named reference like "%<name>s" for a #sprintf argument.
  #
  # @type [Regexp]
  #
  SPRINTF_FMT_NAMED_REFERENCE = /%<([^>]+)>/.freeze

  # Extract the named references in a format string.
  #
  # @param [String]                text   String with #sprintf formatting.
  # @param [Array<Regexp>, Regexp] match  Patterns to match
  #
  # @return [Array<Symbol>]
  #
  # @see Kernel#sprintf
  #
  def named_references(text, match = nil)
    return [] unless text&.include?('%')
    patterns = match || [SPRINTF_NAMED_REFERENCE, SPRINTF_FMT_NAMED_REFERENCE]
    Array.wrap(patterns).flat_map { |pattern|
      text.scan(pattern).map(&:shift)
    }.compact_blank!.uniq.map!(&:to_sym)
  end

  # Parts of a complete #sprintf format as regular expression fragments.
  #
  # @type [Hash{Symbol=>String}]
  #
  #--
  # noinspection SpellCheckingInspection
  #++
  SPRINTF_FMT_PARTS = {
    name:      '(<[^>]+>)',
    flags:     '(\d+\$\*\d+\$|\d+\$|[ #+0-]+)',
    width:     '(\d+)',
    precision: '(\.\d+)',
    type:      '([bBdiouxXeEfgGaAcps])'
  }.freeze

  # Match a named reference along with "%<name>s" the format portion.
  #
  # $1 = [String, nil] named format
  # $2 = [String, nil] flags
  # $3 = [String, nil] width
  # $4 = [String, nil] precision
  # $5 = [String]      type
  #
  # @type [Regexp]
  #
  SPRINTF_FORMAT =
    Regexp.new(
      '%%%{name}?%{flags}?%{width}?%{precision}?%{type}' % SPRINTF_FMT_PARTS
    ).freeze

  # Extract the named references in a format string and pair them with their
  # respective sprintf formats.  Each "%{name}" reference is paired with "%s";
  # each "%<name>" reference is paired with the format which follows it.
  #
  # @param [String]      text         String with #sprintf formatting.
  # @param [String, nil] default_fmt  Format value for "%{name}" matches.
  #
  # @return [Hash{Symbol=>String}]
  #
  def named_references_and_formats(text, default_fmt: '%s')
    return {} unless text&.include?('%')
    result = named_references(text).map { |name| [name, default_fmt] }.to_h
    text.scan(SPRINTF_FORMAT).each do |fmt_parts|
      name = fmt_parts&.shift&.delete('<>')&.presence
      result[name.to_sym] = '%' + fmt_parts.join if name && fmt_parts.present?
    end
    result
  end

end

__loading_end(__FILE__)
