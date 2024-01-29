# lib/emma/common/format_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'erb'

module Emma::Common::FormatMethods

  extend self

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
  # $1 = [String] name
  #
  # @type [Regexp]
  #
  SIMPLE_NAMED_REFERENCE = /%{([^}\n]+)}/.freeze

  # Match a formatted named reference like "%<name>s" for a #sprintf argument.
  #
  # $1 = [String] name
  #
  # @type [Regexp]
  #
  FORMAT_NAMED_REF_BASE = /%<([^>\n]+)>/.freeze

  # @private
  # @type [Array<Regexp>]
  NAMED_REFERENCES = [SIMPLE_NAMED_REFERENCE, FORMAT_NAMED_REF_BASE].freeze

  # Extract the named references in a format string.
  #
  # @param [String, *]             text   String with #sprintf formatting.
  # @param [Array<Regexp>, Regexp] match  Default: #NAMED_REFERENCES
  #
  # @return [Array<Symbol>]
  #
  # @see Kernel#sprintf
  #
  def named_references(text, match: nil)
    return [] unless (text = text.to_s).match?(/%[{<]/)
    match  = match ? Array.wrap(match) : NAMED_REFERENCES
    result = match.flat_map { |pat| text.scan(pat).map(&:shift) }
    result.compact_blank!.map!(&:to_sym).uniq
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Match the format portion of a named reference like "%<name>".
  #
  # $1 = [String, nil] flags
  # $2 = [String, nil] width
  # $3 = [String, nil] precision
  # $4 = [String]      format type
  #
  # @type [Regexp]
  #
  #--
  # noinspection RegExpRedundantEscape, SpellCheckingInspection
  #++
  FORMAT_MATCH = /
    (\d+\$\*\d+\$|\d+\$|[\ #+0-]+)? # $1 - optional flags
    (\d+)?                          # $2 - optional width
    (\.\d+)?                        # $3 - optional precision
    ([bBdiouxXeEfgGcpsaA])          # $4 - required format type
  /x.freeze

  # Match a named reference like "%<name>" along with its format.
  #
  # $1 = [String]      name
  # $2 = [String, nil] flags
  # $3 = [String, nil] width
  # $4 = [String, nil] precision
  # $5 = [String]      format type
  #
  # @type [Regexp]
  #
  FORMAT_NAMED_REFERENCE =
    /#{FORMAT_NAMED_REF_BASE.source}#{FORMAT_MATCH.source}/x.freeze

  # Match a named reference "%{name}" or "%<name>" along with its format.
  #
  # $1 = [String]      name           String for "%{name}"; nil for "%<name>".
  # $2 = [String]      name           String for "%<name>"; nil for "%{name}".
  # $3 = [String, nil] flags          Always nil for "%{name}".
  # $4 = [String, nil] width          Always nil for "%{name}".
  # $5 = [String, nil] precision      Always nil for "%{name}".
  # $6 = [String, nil] format type    String for "%<name>"; nil for "%{name}".
  #
  # @type [Regexp]
  #
  NAMED_REFERENCE =
    Regexp.union(SIMPLE_NAMED_REFERENCE, FORMAT_NAMED_REFERENCE).freeze

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
    result = {}
    text.to_s.scan(NAMED_REFERENCE).each do |parts|
      name = parts.shift || parts.shift
      fmt  = parts.presence&.join || default_fmt
      fmt  = "%#{fmt}" if fmt && !fmt.start_with?('%')
      result[name.to_sym] = fmt
    end
    result
  end

  # Matches the given named reference appearing in a string as "%{name}".
  # Named references of the form "%<name>" will not be matched.
  #
  # @param [String|Symbol] var
  #
  # @return [Regexp]
  #
  def match_simple_named_ref(var)
    /%{#{var}}/
  end

  # Matches the given named reference appearing in a string as "%<name>...".
  # Named references of the form "%{name}" will not be matched.
  #
  # @param [String|Symbol] var
  #
  # @return [Regexp]
  #
  def match_format_named_ref(var)
    /%<#{var}>#{FORMAT_MATCH.source}/x
  end

  # Matches the given named reference appearing in a string as either "%{name}"
  # or "%<name>...".
  #
  # @param [String|Symbol] var
  #
  # @return [Regexp]
  #
  def named_reference_matcher(var)
    Regexp.union(match_simple_named_ref(var), match_format_named_ref(var))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Used by #indefinite_article to find the first substring after "%{an}" or
  # "%<an>" in order to determine whether the subject starts with a vowel.
  #
  # @type [Regexp]
  #
  NAMED_REF_AN = named_reference_matcher(:an).freeze

  # Return the appropriate article ('a' or 'an') for the given word or phrase.
  #
  # If *term* contains "%{an}" or "%<an>...", the substring following it is
  # used to determine whether the subject starts with a vowel.
  #
  # @param [String] term
  #
  # @return [String]
  #
  def indefinite_article(term)
    term  = term.to_s
    term  = term.split(NAMED_REF_AN).second || term if term.match?(/%[{<]/)
    first = term.lstrip[0]
    vowel = first && 'aeiou'.include?(first.downcase)
    config_text(vowel ? :an : :a)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Attempt to apply interpolations to all strings in *item*.
  #
  # @param [Hash, Array, String, *] item
  # @param [Hash]                   opt
  #
  # @return [*]
  #
  def deep_interpolate_named_references(item, **opt)
    case item
      when Hash   then item.transform_values { |v| send(__method__, v, **opt) }
      when Array  then item.map { |v| send(__method__, v, **opt) }
      when String then interpolate_named_references(item, **opt)
      else             item
    end
  end

  # If possible, make a copy of *text* with #sprintf named references replaced
  # by the matching values extracted from *src* or *opt*.  Otherwise return
  # *text* unchanged.
  #
  # If the name is capitalized or all uppercase (e.g. "%{Name}" or "%{NAME}")
  # then the interpolated value will follow the same case.
  #
  # @param [String, *]           text
  # @param [Array<Hash,Model,*>] src
  # @param [Hash]                opt
  #
  # @return [String]                  A modified copy of *text*.
  # @return [nil]                     If no interpolations could be made.
  #
  # === Usage Notes
  # If *text* contains a mix of named references and unnamed specifiers, the
  # assumption is that it will be processed in two passes -- first (by this
  # method) with a hash of values matching the named references generating an
  # intermediate string, then (by the caller) a second pass on that result to
  # supply values for the unnamed specifiers.
  #
  def interpolate_named_references(text, *src, **opt)
    interpolate_named_references!(text, *src, **opt) || text.to_s
  end

  # If possible, make a copy of *text* with #sprintf named references replaced
  # by the matching values extracted from *src* or *opt*.
  #
  # @param [String, *]           text
  # @param [Array<Hash,Model,*>] src
  # @param [Hash]                opt
  #
  # @return [String]                  A modified copy of *text*.
  # @return [nil]                     If no interpolations could be made.
  #
  # @see #interpolate_named_references
  #
  def interpolate_named_references!(text, *src, **opt)
    return if text.blank? || src.push(opt).compact_blank!.empty?
    html   = false
    values =
      named_references_and_formats(text, default_fmt: nil).map { |term, format|
        key  = term.to_s.underscore.to_sym
        val  = nil
        src.find { |item|
          case
            when item.try(:include?, key)  then val = item[key]
            when item.try(:include?, term) then val = item[term]
            when item.respond_to?(key)     then val = item.send(key)
            when item.respond_to?(term)    then val = item.send(term)
            else                                next
          end
          break true
        } or next
        term = term.to_s
        val  = val&.to_s || term
        htm  = val.is_a?(ActiveSupport::SafeBuffer)
        if term.start_with?(/[[:alpha:]]/) && (term == term.capitalize)
          key = key.capitalize
          val = val.capitalize unless htm
        elsif term.match?(/[[:alpha:]]/) && (term == term.upcase)
          key = key.upcase
          val = val.upcase unless htm
        end
        val %= format if format && !htm
        html ||= htm
        [key, val]
      }.compact.presence&.to_h or return
    html ||= text.is_a?(ActiveSupport::SafeBuffer)
    values.transform_values! { |val| ERB::Util.h(val) } if html
    text = text.to_s.gsub(/(?<!%)(%[^{<])/, '%\1')  # Preserve %s specifiers
    text %= values                                  # Interpolate named values
    text = text.gsub(/(?<!%)%(%[^{<])/, '\1')       # Restore %s specifiers
    html ? text.html_safe : text
  end

end

__loading_end(__FILE__)
