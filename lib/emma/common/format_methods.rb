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
    text ||= ''.html_safe
    html   = text.is_a?(ActiveSupport::SafeBuffer)
    text   = ERB::Util.h(text) unless html
    # noinspection RubyMismatchedReturnType
    (html && !force) ? text : text.gsub(/[ \t]/, '&nbsp;').html_safe
  end

  # Render a camel-case or snake-case string as in "title case" words separated
  # by non-breakable spaces.
  #
  # If *text* is already HTML-ready it is returned directly.
  #
  # @param [String, Symbol, nil]  text
  # @param [Integer, nil]         count       To #inflection if present.
  # @param [Boolean]              breakable   If *false* replace spaces with
  #                                             '&nbsp;' so that the result is
  #                                             not word-breakable.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def labelize(text, count: nil, breakable: true, **)
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
  QUOTE_MARKS = %w[ ' " ].freeze

  # @type [Array<ActiveSupport::SafeBuffer>]
  HTML_QUOTES = QUOTE_MARKS.map { |q| ERB::Util.h(q) }.deep_freeze

  # Add surrounding quotation marks to a term.
  #
  # If the term is already quoted, those quotation marks are preserved.
  #
  # @param [*]      term
  # @param [String] quote
  # @param [String] separator
  #
  # @return [ActiveSupport::SafeBuffer, String]
  #
  #--
  # === Variations
  #++
  #
  # @overload quote(terms, quote: '"', separator: ', ')
  #   @param [Array<ActiveSupport::SafeBuffer>] terms
  #   @param [String]                           quote
  #   @param [String]                           separator
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload quote(term, quote: '"', separator: ', ')
  #   @param [ActiveSupport::SafeBuffer] term
  #   @param [String]                    quote
  #   @param [String]                    separator
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload quote(terms, quote: '"', separator: ', ')
  #   @param [Array]  terms
  #   @param [String] quote
  #   @param [String] separator
  #   @return [String]
  #
  # @overload quote(term, quote: '"', separator: ', ')
  #   @param [*]      term
  #   @param [String] quote
  #   @param [String] separator
  #   @return [String]
  #
  def quote(term, quote: '"', separator: ', ')
    # noinspection RubyMismatchedReturnType
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
  # @param [*]      term
  # @param [String] separator
  #
  # @return [ActiveSupport::SafeBuffer, String]
  #
  #--
  # === Variations
  #++
  #
  # @overload strip_quotes(terms, separator: ', ')
  #   @param [Array<ActiveSupport::SafeBuffer>] terms
  #   @param [String]                           separator
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload strip_quotes(term,separator: ', ')
  #   @param [ActiveSupport::SafeBuffer] term
  #   @param [String]                    separator
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload strip_quotes(terms, separator: ', ')
  #   @param [Array]  terms
  #   @param [String] separator
  #   @return [String]
  #
  # @overload strip_quotes(term, separator: ', ')
  #   @param [*]      term
  #   @param [String] separator
  #   @return [String]
  #
  def strip_quotes(term, separator: ', ')
    # noinspection RubyMismatchedReturnType
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

  # @private
  # @type [Array<Regexp>]
  SPRINTF_NAMED_REF_PATTERNS =
    [SPRINTF_NAMED_REFERENCE, SPRINTF_FMT_NAMED_REFERENCE].freeze

  # Extract the named references in a format string.
  #
  # @param [String, *]             text   String with #sprintf formatting.
  # @param [Array<Regexp>, Regexp] match  Patterns to match
  #
  # @return [Array<Symbol>]
  #
  # @see Kernel#sprintf
  #
  def named_references(text, match = SPRINTF_NAMED_REF_PATTERNS)
    return [] unless (text = text.to_s).match?(/%[{<]/)
    matches = Array.wrap(match).flat_map { |pat| text.scan(pat).map(&:shift) }
    matches.compact_blank!.map!(&:to_sym).uniq
  end

  # Match a named reference along with "%<name>s" the format portion.
  #
  # $1 = [String, nil] name
  # $2 = [String, nil] flags
  # $3 = [String, nil] width
  # $4 = [String, nil] precision
  # $5 = [String]      format
  #
  # @type [Regexp]
  #
  #--
  # noinspection RegExpRedundantEscape, SpellCheckingInspection
  #++
  SPRINTF_FORMAT = /
    %                                 # required
    (<[^>]+>)?                        # optional name
    (\d+\$\*\d+\$|\d+\$|[\ #+0-]+)?   # optional flags
    (\d+)?                            # optional width
    (\.\d+)?                          # optional precision
    ([bBdiouxXeEfgGaAcps])            # required format
  /x.freeze

  # Extract the named references in a format string and pair them with their
  # respective sprintf formats.  Each "%{name}" reference is paired with "%s";
  # each "%<name>" reference is paired with the format which follows it.
  #
  # @param [String, *]   text         String with #sprintf formatting.
  # @param [String, nil] default_fmt  Format value for "%{name}" matches.
  #
  # @return [Hash{Symbol=>String}]
  #
  def named_references_and_formats(text, default_fmt: '%s')
    named_references(text).map { |name| [name, default_fmt] }.to_h.tap do |res|
      if res.present?
        text.to_s.scan(SPRINTF_FORMAT).each do |parts|
          next if (name = parts.shift).blank? || (fmt = parts.join).blank?
          res[name.delete('<>').to_sym] = "%#{fmt}"
        end
      end
    end
  end

  # Make a copy of *text* with #sprintf named references replaced by the
  # matching values extracted from *items* or *opt*.
  #
  # If the name is capitalized or all uppercase (e.g. "%{Name}" or "%{NAME}")
  # then the interpolated value will follow the same case.
  #
  # @param [String, *]           text
  # @param [Array<Hash,Model,*>] items
  # @param [Hash]                opt
  #
  # @return [String]                  A (possibly modified) copy of *text*.
  #
  # === Usage Notes
  # If *text* contains a mix of named references and unnamed specifiers, the
  # assumption is that it will be processed in two passes -- first (by this
  # method) with a hash of values matching the named references generating an
  # intermediate string, then (by the caller) a second pass on that result to
  # supply values for the unnamed specifiers.
  #
  def interpolate_named_references(text, *items, **opt)
    interpolate_named_references!(text, *items, **opt) || text.to_s
  end

  # Replace #sprintf named references in *text* with the matching values
  # extracted from *items* or *opt*.
  #
  # @param [String, *]           text
  # @param [Array<Hash,Model,*>] items
  # @param [Hash]                opt
  #
  # @return [String]                  A modified copy of *text*.
  # @return [nil]                     If no interpolations could be made.
  #
  # @see #interpolate_named_references
  #
  def interpolate_named_references!(text, *items, **opt)
    items  = [*items, opt].compact_blank!.presence or return
    values =
      named_references_and_formats(text, default_fmt: nil).map { |term, format|
        term = term.to_s
        key  = term.underscore.to_sym
        val  = nil
        items.find { |item|
          item.respond_to?(key) and break (val = item.send(key)) || true
          item.include?(key)    and break (val = item[key])      || true
        } or next
        val = val&.to_s || term
        if term.match?(/[[:alpha:]]/)
          if term == term.upcase
            key, val = [key, val].map(&:upcase)
          elsif (term == term.capitalize) && term.start_with?(/[[:alpha:]]/)
            key, val = [key, val].map(&:capitalize)
          end
        end
        val %= format if format
        [key, val]
      }.compact.presence or return
    text = text.to_s.gsub(/(?<!%)(%[^{<])/, '%\1')  # Preserve %s specifiers
    text %= values.to_h                             # Interpolate
    text.gsub(/(?<!%)%(%[^{<])/, '\1')              # Restore %s specifiers
  end

end

__loading_end(__FILE__)
