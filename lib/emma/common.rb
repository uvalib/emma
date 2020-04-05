# lib/emma/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# General support methods.
#
module Emma::Common

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
  # @param [Object] value
  #
  def boolean?(value)
    case value
      when TrueClass, FalseClass then true
      when Array, Hash, nil      then false
      else BOOLEAN_VALUES.include?(value.to_s.strip.downcase)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Interpret *value* as a positive integer.
  #
  # @param [String, Numeric] value
  #
  # @return [Integer]
  # @return [nil]                     If *value* <= 0 or not a number.
  #
  def positive(value)
    result = value.to_i
    result if result > 0
  end

  # Interpret *value* as zero or a positive integer.
  #
  # @param [String, Numeric] value
  #
  # @return [Integer]
  # @return [nil]                     If *value* < 0 or not a number.
  #
  def non_negative(value)
    result = value.to_i
    result unless value.blank? || (result < 0)
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
  # "myReadingLists/%{id}?delete".
  #
  # @param [Array] args               URL path components, except:
  #
  # @option args.last [Hash]          URL options to include in the result.
  #
  # @return [String]
  #
  def make_path(*args)
    opt = args.extract_options!
    url = args.flatten.join('/').lstrip.sub(/[?&\s]+$/, '')
    url, query = url.split('?', 2)
    parts = query.to_s.split('&').reject(&:blank?)
    first = (parts.shift unless parts.blank? || parts.first.include?('='))
    query = url_query(parts, opt).presence
    url << '?'   if first || query
    url << first if first
    url << '&'   if first && query
    url << query if query
    # noinspection RubyYardReturnMatch
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
  # @return [String]
  #
  # @see #build_query_options
  #
  def url_query(*args)
    opt = args.extract_options!.reverse_merge(minimize: true, decorate: true)
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
  # @return [Hash{String=>String}]
  #
  def build_query_options(*args)
    opt = args.extract_options!.reverse_merge(minimize: true, decorate: false)
    minimize = opt.delete(:minimize)
    decorate = opt.delete(:decorate)
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
        v = Array.wrap(v).reject(&:blank?).map { |s| CGI.unescape(s.to_s) }
        res[k] = res[k] ? res[k].rmerge!(v) : v if k.present? && v.present?
      end
      result.rmerge!(res)
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
  # @param [ActionController::Parameters, Hash] hash
  # @param [Array<Symbol>]                      keys
  #
  # @return [Array<(Hash, Hash)>]   Matching hash followed by remainder hash.
  #
  def partition_options(hash, *keys)
    hash ||= {}
    hash = request_parameters(hash) if hash.is_a?(ActionController::Parameters)
    keys = keys.flatten.compact.map(&:to_sym).uniq
    opt  = hash.slice(*keys)
    rem  = hash.except(*opt.keys)
    return opt, rem
  end

  # Recursive remove blank items from a hash.
  #
  # @param [Hash] item
  #
  # @return [Hash]
  #
  # @see #remove_blanks
  #
  def reject_blanks(item)
    remove_blanks(item) || {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Recursively remove blank items from an object.
  #
  # @overload remove_blanks(item)
  #   @param [Hash] item
  #   @return [Hash, nil]
  #
  # @overload remove_blanks(item)
  #   @param [Array] item
  #   @return [Array, nil]
  #
  # == Usage Notes
  # Empty strings and nils are considered blank, however an item or element
  # with the explicit value of *false* is not considered blank.
  #
  def remove_blanks(item)
    case item
      when TrueClass, FalseClass
        item
      when Hash
        item.transform_values { |v| remove_blanks(v) }.compact.presence
      when Array
        item.map { |v| remove_blanks(v) }.compact.presence
      else
        item.presence
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the name of the calling method.
  #
  # @overload calling_method(call_stack = nil)
  #   @param [Array<String>] call_stack   Default: `#caller(2)`.
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
    call_stack.find do |line|
      _file_line, name = line.to_s.split(/:in\s+/)
      name = name.to_s.sub(/^[ `]*(.*?)[' ]*$/, '\1').presence
      case name
        when nil, 'each', 'map', '__output' then next
        when /^(block|rescue)\s+in\s+(.*)$/ then return $2
        else                                     return name
      end
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
    s = (s =~ /%[0-9a-fA-F]{2}/) ? s.tr(' ', '+') : CGI.escape(s)
    s.tr('.', '%2E')
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
      keys.reject!(&:blank?)
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
  # @param [String] string
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
  #
  # @return [Array<String>]
  #
  def normalized_list(values, **opt)
    opt[:sanitize] = true unless opt.key?(:sanitize)
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
          value = value.to_s
          value = sanitized_string(value) if opt[:sanitize]
          value = quote(value)            if opt[:quote]
          value
      end
    }.reject(&:blank?)
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
  # @param [String]  text
  # @param [Boolean] force            If *true* then the translation will
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
  # @param [String, Symbol]       text
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

  # Transform a string into a value safe for use as an HTML ID (or class name).
  #
  # @param [String, Symbol] text
  #
  # @return [String]
  #
  def html_id(text)
    # noinspection RubyYardParamTypeMatch
    text = sanitized_string(text) if text.is_a?(ActiveSupport::SafeBuffer)
    text.to_s.tr(' ', '_').underscore.camelize
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

end

__loading_end(__FILE__)
