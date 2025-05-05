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
    return text if text.is_a?(ActiveSupport::SafeBuffer)
    result =
      Array.wrap(text)
        .flat_map { |s| s.to_s.split(/[_\s]/) if s.present? }
        .flat_map { |s|
          next if s.blank?
          s = s.upcase_first.gsub(/[A-Z]+[^A-Z]+/, '\0 ').rstrip
          s.split(' ').map { (_1 == 'Id') ? _1.upcase : _1 }
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
  HTML_QUOTES = QUOTE_MARKS.map { ERB::Util.h(_1) }.deep_freeze

  # Add surrounding quotation marks to a term.
  #
  # If the term is already quoted, those quotation marks are preserved.
  #
  # @param [any, nil] term
  # @param [String]   q_char
  # @param [String]   separator
  #
  # @return [ActiveSupport::SafeBuffer, String]
  #
  #--
  # === Variations
  #++
  #
  # @overload quote(terms, q_char: '"', separator: ', ')
  #   @param [Array<ActiveSupport::SafeBuffer>] terms
  #   @param [String]                           q_char
  #   @param [String]                           separator
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload quote(term, q_char: '"', separator: ', ')
  #   @param [ActiveSupport::SafeBuffer] term
  #   @param [String]                    q_char
  #   @param [String]                    separator
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload quote(terms, q_char: '"', separator: ', ')
  #   @param [Array]  terms
  #   @param [String] q_char
  #   @param [String] separator
  #   @return [String]
  #
  # @overload quote(term, q_char: '"', separator: ', ')
  #   @param [any, nil] term
  #   @param [String]   q_char
  #   @param [String]   separator
  #   @return [String]
  #
  def quote(term, q_char: '"', separator: ', ')
    if term.is_a?(Array)
      terms = term.map { quote(_1, q_char: q_char, separator: separator) }
      html  = terms.all?(&:html_safe?)
      html ? html_join(terms, separator) : terms.join(separator)

    elsif !term.is_a?(String)
      "#{q_char}#{term}#{q_char}"

    elsif term.html_safe?
      q_char = ERB::Util.h(q_char)
      quotes = [*HTML_QUOTES, q_char].uniq
      quoted = quotes.any? { term.start_with?(_1) && term.end_with?(_1) }
      quoted ? term : "#{q_char}#{term}#{q_char}".html_safe

    else
      term   = term.strip
      quotes = [*QUOTE_MARKS, q_char].uniq
      quoted = quotes.any? { term.start_with?(_1) && term.end_with?(_1) }
      quoted ? term : "#{q_char}#{term}#{q_char}"
    end
  end

  # Remove pairs of surrounding quotation marks from a term.
  #
  # @param [any, nil] term
  # @param [String]   separator
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
  #   @param [any, nil] term
  #   @param [String]   separator
  #   @return [String]
  #
  def strip_quotes(term, separator: ', ')
    if term.is_a?(Array)
      terms = term.map { strip_quotes(_1, separator: separator) }
      html  = terms.all?(&:html_safe?)
      html ? html_join(terms, separator) : terms.join(separator)
    elsif !term.is_a?(String)
      term.to_s
    elsif term.html_safe?
      quote = HTML_QUOTES.find { term.start_with?(_1) && term.end_with?(_1) }
      quote ? term.delete_prefix(quote).delete_suffix(quote).html_safe : term
    else
      term  = term.to_s.strip
      quote = QUOTE_MARKS.find { term.start_with?(_1) && term.end_with?(_1) }
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
  # @param [any, nil]              text   String with #sprintf formatting.
  # @param [Array<Regexp>, Regexp] match  Default: #NAMED_REFERENCES
  #
  # @return [Array<Symbol>]
  #
  # @see Kernel#sprintf
  #
  def named_references(text, match: nil)
    return [] unless (text = text.to_s).match?(/%[{<]/)
    match  = match ? Array.wrap(match) : NAMED_REFERENCES
    result = match.flat_map { text.scan(_1).map(&:shift) }
    result.compact_blank.map!(&:to_sym).uniq
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
  # respective sprintf formats.  Each "%{name}" reference is paired with *nil*;
  # each "%<name>" reference is paired with the format which follows it.
  #
  # @param [any, nil] text            String with #sprintf formatting.
  #
  # @return [Hash{Symbol=>String,nil}]
  #
  def named_references_and_formats(text)
    text.to_s.scan(NAMED_REFERENCE).map { |parts|
      name = parts.shift || parts.shift
      fmt  = parts.compact.presence&.join
      fmt  = "%#{fmt}" if fmt && !fmt.start_with?('%')
      [name.to_sym, fmt]
    }.to_h
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
    config_term(vowel ? :an : :a)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Attempt to apply interpolations to all strings in *item*.
  #
  # @param [any, nil] item            Hash, Array, String
  # @param [Hash]     opt
  #
  # @return [any, nil]
  #
  def deep_interpolate(item, **opt)
    case item
      when Hash   then item.transform_values { deep_interpolate(_1, **opt) }
      when Array  then item.map { deep_interpolate(_1, **opt) }
      when String then interpolate(item, **opt)
      else             item
    end
  end

  # If possible, make a copy of *text* with #sprintf named references replaced
  # by the matching values extracted from *src* or *opt*.  Otherwise, return
  # *text* unchanged.
  #
  # If the name is capitalized or all uppercase (e.g. "%{Name}" or "%{NAME}")
  # then the interpolated value will follow the same case.
  #
  # @param [any, nil]            text
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
  def interpolate(text, *src, **opt)
    interpolate!(text, *src, **opt) || text.to_s
  end

  # If possible, make a copy of *text* with #sprintf named references replaced
  # by the matching values extracted from *src* or *opt*.
  #
  # @param [any, nil]            text
  # @param [Array<Hash,Model,*>] src
  # @param [Hash]                opt
  #
  # @return [String]                  A modified copy of *text*.
  # @return [nil]                     If no interpolations could be made.
  #
  def interpolate!(text, *src, **opt)
    return if text.blank? || src.push(opt).compact_blank!.empty?

    text   = text.to_s
    html   = false
    values =
      named_references_and_formats(text).map { |term, format|
        key = term.to_s.underscore.to_sym
        val = nil
        src.each do |item|
          case
            when item.try(:include?, key)  then val = item[key]
            when item.try(:include?, term) then val = item[term]
            when item.respond_to?(key)     then val = item.send(key)
            when item.respond_to?(term)    then val = item.send(term)
            else                                next
          end
          break
        end
        term  = term.to_s
        val   = val&.to_s
        val ||= "%{#{term}}" # Named reference will show as un-interpolated.
        htm   = val.html_safe?
        if term.start_with?(/[[:alpha:]]/) && (term == term.capitalize)
          key = key.capitalize
          val = val.capitalize unless htm
        elsif term.match?(/[[:alpha:]]/) && (term == term.upcase)
          key = key.upcase
          val = val.upcase unless htm
        end
        val %= format if format
        html ||= htm
        [key, val]
      }.compact.presence&.to_h or return

    html ||= text.html_safe?
    text   = text.gsub(/(?<!%)(%[^{<])/,  '%\1')  # Preserve %s specifiers
    text  %= html ? values.transform_values! { ERB::Util.h(_1) } : values
    text   = text.gsub(/(?<!%)%(%[^{<])/, '\1')   # Restore %s specifiers
    html ? text.html_safe : text
  end

end

__loading_end(__FILE__)
