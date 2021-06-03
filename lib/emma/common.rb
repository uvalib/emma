# lib/emma/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'sanitize'

# General support methods.
#
module Emma::Common

  # @private
  def self.included(base)
    base.send(:extend, self)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Text values which represent a Boolean value.
  #
  # @type [Array<String>]
  #
  BOOLEAN_VALUES = (TRUE_VALUES + FALSE_VALUES).sort_by!(&:length).freeze

  # Indicate whether the item represents a true or false value.
  #
  # @param [*] value
  #
  def boolean?(value)
    return true  if value.is_a?(TrueClass) || value.is_a?(FalseClass)
    return false unless value.is_a?(String) || value.is_a?(Symbol)
    BOOLEAN_VALUES.include?(value.to_s.strip.downcase)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Interpret *value* as a positive integer.
  #
  # @param [String, Symbol, Numeric, nil] value
  #
  # @return [Integer]
  # @return [nil]                     If *value* <= 0 or not a number.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def positive(value)
    result =
      case value
        when Integer then value
        when Numeric then value.round
        else              value.to_s.to_i
      end
    result if result.positive?
  end

  # Interpret *value* as zero or a positive integer.
  #
  # @param [String, Symbol, Numeric, nil] value
  #
  # @return [Integer]
  # @return [nil]                     If *value* < 0 or not a number.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def non_negative(value)
    return if value.blank?
    result =
      case value
        when Integer then value
        when Numeric then value.round
        else              value.to_s.to_i
      end
    result unless result.negative?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given string value contains only decimal digits.
  #
  # @param [*] value
  #
  def digits_only?(value)
    case value
      when Integer, ActiveModel::Type::Integer, ActiveSupport::Duration
        true
      when String, Symbol, Numeric, ActiveModel::Type::Float
        (value = value.to_s).present? && value.delete('0-9').blank?
      else
        false
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a URL or partial path.
  #
  # The result will have query parameters in sorted order.  Query parameters
  # are assumed to have the form "key=value" with the exception of the first
  # parameter after the '?' -- this is a concession to Bookshare URLs like
  # "myReadingLists/(id)?delete".
  #
  # @param [Array] args               URL path components, except for args[-1]
  #                                     which is passed as #url_query options.
  #
  # @return [String]
  #
  #--
  # noinspection RubyNilAnalysis, RubyYardParamTypeMatch
  #++
  def make_path(*args)
    opt = args.extract_options!
    url = args.flatten.join('/').lstrip.sub(/[?&\s]+$/, '')
    url, query = url.split('?', 2)
    parts = query.to_s.split('&').compact_blank
    first = (parts.shift unless parts.blank? || parts.first.include?('='))
    query = url_query(parts, opt).presence
    url << '?'   if first || query
    url << first if first
    url << '&'   if first && query
    url << query if query
    url
  end

  # Combine URL query parameters into a URL query string.
  #
  # @param [Array<URI,String,Array,Hash>] args
  #
  # @option args.last [Boolean] :minimize   If *false*, do not reduce single-
  #                                           element array values to scalars
  #                                           (default: *true*).
  #
  # @option args.last [Boolean] :decorate   If *false*, do not modify keys for
  #                                           multi-element array values
  #                                           (default: *true*).
  #
  # @option args.last [Boolean] :replace    If *true*, subsequence key values
  #                                           replace previous ones; if *false*
  #                                           then values are accumulated as
  #                                           arrays (default: *false*).
  #
  # @return [String]
  #
  # @see #build_query_options
  #
  def url_query(*args)
    opt = { decorate: true, unescape: false }.merge!(args.extract_options!)
    build_query_options(*args, opt).flat_map { |k, v|
      v.is_a?(Array) ? v.map { |e| "#{k}=#{e}" } : "#{k}=#{v}"
    }.compact.join('&')
  end

  # Transform URL query parameters into a hash.
  #
  # @param [Array<URI,String,Array,Hash>] args
  #
  # @option args.last [Boolean] :minimize   If *false*, do not reduce single-
  #                                           element array values to scalars
  #                                           (default: *true*).
  #
  # @option args.last [Boolean] :decorate   If *true*, modify keys for multi-
  #                                           element values (default: *false*)
  #
  # @option args.last [Boolean] :replace    If *true*, subsequence key values
  #                                           replace previous ones; if *false*
  #                                           then values are accumulated as
  #                                           arrays (default: *false*).
  #
  # @option args.last [Boolean] :unescape   If *false*, do not unescape values.
  #
  # @return [Hash{String=>String}]
  #
  def build_query_options(*args)
    opt = {
      minimize: true,
      decorate: false,
      replace:  false,
      unescape: true
    }.merge!(args.extract_options!)
    minimize = opt.delete(:minimize)
    decorate = opt.delete(:decorate)
    replace  = opt.delete(:replace)
    unescape = opt.delete(:unescape)
    opt      = reject_blanks(opt)
    args << opt if opt.present?
    result = {}
    args.each do |arg|
      arg = arg.query      if arg.is_a?(URI)
      arg = arg.split('&') if arg.is_a?(String)
      arg = arg.to_a       if arg.is_a?(Hash)
      next unless arg.is_a?(Array) && arg.present?
      res = {}
      arg.each do |pair|
        k, v = pair.is_a?(Array) ? pair : pair.to_s.split('=', 2)
        k = CGI.unescape(k.to_s).delete_suffix('[]')
        v = Array.wrap(v).compact_blank
        next if k.blank? || v.blank?
        v.map!(&:to_s)
        v.map! { |s| CGI.unescape(s) } if unescape
        if replace || !res[k]
          res[k] = v
        else
          res[k].rmerge!(v)
        end
      end
      if replace
        result.merge!(res)
      else
        result.rmerge!(res)
      end
    end
    result.map { |k, v|
      v = v.sort.uniq
      v = v.first  if minimize && (v.size <= 1)
      k = "#{k}[]" if decorate && v.is_a?(Array)
      [k, v]
    }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Strip off the hash elements identified by *keys* to return two hashes:
  # - First, a hash containing only the requested option keys and values.
  # - Second, a copy of the original *hash* without the those keys/values.
  #
  # @param [ActionController::Parameters, Hash, nil] hash
  # @param [Array<Symbol>]                           keys
  #
  # @return [(Hash, Hash)]            Matching hash followed by remainder hash.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def partition_options(hash, *keys)
    hash ||= {}
    hash = request_parameters(hash) if hash.is_a?(ActionController::Parameters)
    keys = keys.flatten.compact.map(&:to_sym).uniq
    opt  = hash.slice(*keys)
    rem  = hash.except(*opt.keys)
    return opt, rem
  end

  # Recursively remove blank items from a hash.
  #
  # @param [Hash, nil]    item
  # @param [Boolean, nil] reduce      If *true* transform arrays with a single
  #                                     element into scalars.
  #
  # @return [Hash]
  #
  # @see #_remove_blanks
  #
  def reject_blanks(item, reduce = false)
    # noinspection RubyYardReturnMatch
    item.is_a?(Hash) && _remove_blanks(item, reduce) || {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Recursively remove blank items from an object.
  #
  # @param [Hash, Array, *] item
  # @param [Boolean, nil]   reduce    If *true* transform arrays with a single
  #                                     element into scalars.
  #
  # @return [Hash, Array, *]
  #
  # == Variations
  #
  # @overload _remove_blanks(hash)
  #   @param [Hash]         hash
  #   @param [Boolean, nil] reduce
  #   @return [Hash, nil]
  #
  # @overload _remove_blanks(array)
  #   @param [Array]        array
  #   @param [Boolean, nil] reduce
  #   @return [Array, nil]
  #
  # @overload _remove_blanks(item)
  #   @param [*]            item
  #   @param [Boolean, nil] reduce
  #   @return [*]
  #
  # == Usage Notes
  # Empty strings and nils are considered blank, however an item or element
  # with the explicit value of *false* is not considered blank.
  #
  def _remove_blanks(item, reduce = false)
    if item.is_a?(Hash)
      item.transform_values { |v| _remove_blanks(v, reduce) }.compact.presence
    elsif item.is_a?(Array)
      result = item.map { |v| _remove_blanks(v, reduce) }.compact.presence
      (reduce && (result&.size == 1)) ? result.first : result
    else
      # noinspection RubyYardReturnMatch
      item.is_a?(FalseClass) ? item : item.presence
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the name of the calling method.
  #
  # @param [Array<String>, Integer, nil] call_stack
  #
  # @return [String, nil]
  #
  # == Variations
  #
  # @overload calling_method()
  #   Using *call_stack* defaulting to `#caller(2)`.
  #   @return [String]
  #
  # @overload calling_method(call_stack)
  #   @param [Array<String>] call_stack
  #   @return [String]
  #
  # @overload calling_method(depth)
  #   @param [Integer] depth              Call stack depth (default: 2)
  #   @return [String]
  #
  def calling_method(call_stack = nil)
    depth = 2
    if call_stack.is_a?(Integer)
      depth = call_stack if call_stack > depth
      call_stack = nil
    end
    call_stack ||= caller(depth)
    # noinspection RubyYardReturnMatch
    call_stack&.find do |line|
      _file_line, name = line.to_s.split(/:in\s+/)
      name = name.to_s.sub(/^[ `]*(.*?)[' ]*$/, '\1')
      next if name.blank?
      next if %w(each map __output __output_impl).include?(name)
      return name.match(/^(block|rescue)\s+in\s+(.*)$/) ? $2 : name
    end
  end

  # Return the indicated method.  If *meth* is something other than a Symbol or
  # a Method then *nil* is returned.
  #
  # @overload get_method(meth, *)
  #   @param [Method] meth
  #   @return [Method]
  #
  # @overload get_method(bind, *)
  #   @param [Binding] bind
  #   @return [Method, nil]
  #
  # @overload get_method(meth, bind, *)
  #   @param [Symbol]  meth
  #   @param [Binding] bind
  #   @return [Method, nil]
  #
  def get_method(*args)
    meth = (args.shift unless args.first.is_a?(Binding))
    return meth if meth.is_a?(Method)
    bind = args.first
    return unless bind.is_a?(Binding)
    meth ||= bind.eval('__method__')
    bind.receiver.method(meth) if bind.receiver.methods.include?(meth)
  end

  # Return a table of a method's parameters and their values given a Binding
  # from that method invocation.
  #
  # @overload get_params(bind, **opt)
  #   @param [Binding]        bind
  #   @param [Hash]           opt
  #
  # @overload get_params(meth, bind, **opt)
  #   @param [Symbol, Method] meth
  #   @param [Binding]        bind
  #   @param [Hash]           opt
  #
  # @option opt [Symbol, Array<Symbol>] :only
  # @option opt [Symbol, Array<Symbol>] :except
  #
  # @return [Hash{Symbol=>*}]
  #
  def get_params(*args)
    opt    = args.extract_options!
    only   = Array.wrap(opt[:only]).presence
    except = Array.wrap(opt[:except]).presence
    meth   = (args.shift unless args.first.is_a?(Binding))
    bind   = (args.shift if args.first.is_a?(Binding))
    if !meth.is_a?(Method) && bind.is_a?(Binding)
      meth = bind.eval('__method__') unless meth.is_a?(Symbol)
      rcvr = bind.receiver
      meth = (rcvr.method(meth) if rcvr.methods.include?(meth))
    end
    prms = meth.is_a?(Method) ? meth.parameters : {}
    prms.flat_map { |type, name|
      next if (type == :block) || name.blank? || except&.include?(name)
      next unless only.nil? || only.include?(name)
      if type == :keyrest
        bind.local_variable_get(name).map(&:itself)
      else
        [[name, bind.local_variable_get(name)]]
      end
    }.compact.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fully URL-encode (including transforming '.' to '%2E') without escaping a
  # string which is already escaped.
  #
  # @param [String] s
  #
  # @return [String]
  #
  def url_escape(s)
    s = s.to_s
    s = s.match?(/%[0-9a-fA-F]{2}/) ? s.tr(' ', '+') : CGI.escape(s)
    s.gsub(/[.]/, '%2E')
  end

  # Extract the named references in a format string.
  #
  # @param [String] format_string
  #
  # @return [Array<Symbol>]
  #
  # @see Kernel#sprintf
  #
  def named_format_references(format_string)
    keys = []
    if format_string.present?
      format_string.scan(/%<([^<>]+)>/) { |name| keys += name } # "%<name>s"
      format_string.scan(/%{([^{}]+)}/) { |name| keys += name } # "%{name}"
      keys.compact_blank!
      keys.uniq!
      keys.map!(&:to_sym)
    end
    keys
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generic text list separator.
  #
  # @type [String]
  #
  LIST_SEPARATOR = ', '

  # Separator between pairs of values (from a Hash).
  #
  # @type [String]
  #
  PAIR_SEPARATOR = '; '

  # Strip HTML from value strings.
  #
  # @param [String, Symbol] string
  #
  # @return [String]
  #
  def sanitized_string(string)
    text = CGI.unescapeHTML(string.to_s).gsub(/&nbsp;/, ' ')
    Sanitize.fragment(text).squish
  end

  # Generate a rendering of a hash as a delimited list of key-value pairs.
  #
  # @param [Hash] hash
  # @param [Hash] opt                 Passed to #normalized_list; used locally:
  #
  # @option opt [String] :pair_separator   Default: #PAIR_SEPARATOR.
  #
  # @return [String]
  #
  def hash_string(hash, **opt)
    pair_separator = opt[:pair_separator] || PAIR_SEPARATOR
    normalized_list(hash, **opt).join(pair_separator)
  end

  # Generate a rendering of an array as a delimited list of elements.
  #
  # @param [Array] array
  # @param [Hash]  opt                Passed to #normalized_list; used locally:
  #
  # @option opt [String] :list_separator   Default: #LIST_SEPARATOR.
  #
  # @return [String]
  #
  def array_string(array, **opt)
    list_separator = opt[:list_separator] || LIST_SEPARATOR
    normalized_list(array, **opt).join(list_separator)
  end

  # Normalize nested arrays/hashes into a flat array of strings.
  #
  # @param [String, Symbol, Hash, Array<String,Symbol,Hash>] values
  # @param [Hash]                                            opt
  #
  # @option opt [String]  :pair_separator   Passed to #hash_string.
  # @option opt [String]  :list_separator   Passed to #array_string.
  # @option opt [Boolean] :sanitize         Strip HTML from value strings
  #                                           (default: *true*).
  # @option opt [Boolean] :quote            Quote string values
  #                                           (default: *false*)
  # @option opt [Boolean] :inspect          Replace "v" with "v.inspect"
  #                                           (default: *false*)
  #
  # @return [Array<String>]
  #
  def normalized_list(values, **opt)
    opt[:sanitize] = true unless opt.key?(:sanitize)
    sanitize = opt[:sanitize]
    Array.wrap(values).flat_map { |value|
      case value
        when Hash
          value.map do |k, v|
            case v
              when Hash  then v = hash_string(v, **opt)
              when Array then v = array_string(v, **opt)
              else            v = normalized_list(v, **opt).first
            end
            "#{k}: #{v}" if v.present?
          end
        when Array
          array_string(value, **opt)
        else
          value = sanitized_string(value) if sanitize && value.is_a?(String)
          if opt[:inspect]
            value.inspect
          elsif opt[:quote]
            quote(value)
          else
            value.to_s
          end
      end
    }.compact_blank!
  end

  # Transform a hash into a struct recursively.  (Any hash value which is
  # itself a hash will be converted to a struct).
  #
  # @param [Hash]         hash
  # @param [Boolean, nil] arrays      If *true*, convert hashes within arrays.
  #
  # @return [Struct]
  #
  def struct(hash, arrays = false)
    keys   = hash.keys.map(&:to_sym)
    values = hash.values_at(*keys)
    values.map! do |v|
      case v
        when Array then arrays ? v.map { |elem| struct(elem, arrays) } : v
        when Hash  then struct(v, arrays)
        else            v
      end
    end
    Struct.new(*keys).new(*values)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  INFLECT_SINGULAR = %i[single singular singularize].freeze
  INFLECT_PLURAL   = %i[plural pluralize].freeze

  # Pluralize or singularize *text*.  If neither *inflection* nor *count* is
  # specified then a copy of the original string is returned.
  #
  # @overload infection(text, inflection = nil, count = nil)
  #   @param [ActiveSupport::Buffer] text
  #   @param [Symbol, Integer, nil]  inflection
  #   @param [Integer, nil]          count
  #   @return [ActiveSupport::Buffer]
  #
  # @overload infection(text, inflection = nil, count = nil)
  #   @param [String]                text
  #   @param [Symbol, Integer, nil]  inflection
  #   @param [Integer, nil]          count
  #   @return [String]
  #
  # @see #INFLECT_SINGULAR
  # @see #INFLECT_PLURAL
  #
  def inflection(text, inflection = nil, count = nil)
    count, inflection = [inflection, nil] if inflection.is_a?(Integer)
    if (count == 1) || INFLECT_SINGULAR.include?(inflection)
      text.to_s.singularize
    elsif count.is_a?(Integer) || INFLECT_PLURAL.include?(inflection)
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
    # noinspection RubyYardReturnMatch
    text
  end

  # Render a camel-case or snake-case string as in "title case" words separated
  # by non-breakable spaces.
  #
  # If *text* is already HTML-ready it is returned directly.
  #
  # @param [String, Symbol, nil]  text
  # @param [Integer, Symbol, nil] count       Passed to #inflection.
  # @param [Boolean]              breakable   If *false* replace spaces with
  #                                             '&nbsp;' so that the result is
  #                                             not word-breakable.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def labelize(text, count = nil, breakable: true)
    # noinspection RubyYardReturnMatch
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
  HTML_ID_IGNORED = ASCII.remove(/[^[:punct:]]/)

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
    separator ||= ''
    word_break  = HTML_ID_WORD_BREAK + separator
    ignored     = HTML_ID_IGNORED.delete(separator)
    parts.map { |part|
      part = sanitized_string(part) if part.is_a?(ActiveSupport::SafeBuffer)
      part = part.to_s
      part = part.tr_s(word_break, ' ').strip.tr(' ', separator)
      part = part.delete(ignored)
      part = part.underscore if underscore || camelize
      part = part.camelize   if camelize
      part.presence
    }.compact.join(separator).tap { |result|
      # noinspection RubyResolve
      result.prepend('Z') if result.start_with?(/[^a-z]/i)
    }
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
  #   @param [ActiveSupport::Buffer] term
  #   @param [String]                quote
  #   @param [String]                separator
  #   @return [ActiveSupport::Buffer]
  #
  # @overload quote(terms, quote: '"', separator: ', ')
  #   @param [Array<ActiveSupport::Buffer>] terms
  #   @param [String]                       quote
  #   @param [String]                       separator
  #   @return [ActiveSupport::Buffer]
  #
  def quote(term, quote: '"', separator: ', ')
    if term.is_a?(Array)
      terms = term.map { |t| quote(t, quote: quote, separator: separator) }
      term  = terms.join(separator)
      terms.all?(&:html_safe?) ? term.html_safe : term

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
  #   @param [ActiveSupport::Buffer] term
  #   @param [String]                separator
  #   @return [ActiveSupport::Buffer]
  #
  # @overload strip_quotes(terms, separator: ', ')
  #   @param [Array<ActiveSupport::Buffer>] terms
  #   @param [String]                       separator
  #   @return [ActiveSupport::Buffer]
  #
  def strip_quotes(term, separator: ', ')
    if term.is_a?(Array)
      terms  = term.map { |t| strip_quotes(t, separator: separator) }
      result = terms.join(separator)
      terms.all?(&:html_safe?) ? result.html_safe : result
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

  # Exceptions which are more likely to indicate unexpected exceptions (i.e.,
  # programming problems) and not operational exceptions due to external API
  # failures.
  #
  # @type [Array<Class>] Sub-classes of Exception.
  #
  INTERNAL_EXCEPTION = [
    NoMemoryError,
    ScriptError,
    SignalException,
    ArgumentError,
    IndexError,
    LocalJumpError,
    NameError,
    RangeError,
    RegexpError,
    SecurityError,
    SystemCallError,
    SystemStackError,
    ThreadError,
    TypeError,
    ZeroDivisionError
  ].freeze

  # Indicate whether *error* is an exception which matches or is derived from
  # one of the exceptions listed in #INTERNAL_EXCEPTION.
  #
  # @param [Exception, *] error
  #
  def internal_exception?(error)
    ancestors = (error.is_a?(Class) ? error : error.class).ancestors
    ancestors.size > (ancestors - INTERNAL_EXCEPTION).size
  end

  # Indicate whether *error* is an exception which is not (derived from) one of
  # the exceptions listed in #INTERNAL_EXCEPTION.
  #
  # @param [Exception, *] error
  #
  def operational_exception?(error)
    a = (error.is_a?(Class) ? error : error.class).ancestors
    a.include?(Exception) && (a.size == (a - INTERNAL_EXCEPTION).size)
  end

  # Re-raise an exception which indicates a likely programming error.
  #
  # @param [Exception, *] error
  #
  # == Usage Notes
  # The re-raise will happen only when running on the desktop.
  #
  def re_raise_if_internal_exception(error)
    raise error if internal_exception?(error)
  end
    .tap { |meth| neutralize(meth) if application_deployed? }

end

__loading_end(__FILE__)
