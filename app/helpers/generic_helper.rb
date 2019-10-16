# app/helpers/generic_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# General support methods.
#
module GenericHelper

  def self.included(base)
    __included(base, '[GenericHelper]')
    base.send(:extend, self)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Text values which represent *true*.
  #
  # @type [Array<String>]
  #
  TRUE_VALUES  = %w(1 yes true).freeze

  # Text values which represent *false*.
  #
  # @type [Array<String>]
  #
  FALSE_VALUES = %w(0 no false).freeze

  # Text values which represent a Boolean value.
  #
  # @type [Array<String>]
  #
  BOOLEAN_VALUES = (TRUE_VALUES + FALSE_VALUES).sort_by!(&:length).freeze

  # Indicate whether the item represents a true value.
  #
  # @param [Object] value
  #
  def true?(value)
    case value
      when TrueClass, FalseClass then value
      when Array, Hash, nil      then false
      else TRUE_VALUES.include?(value.to_s.strip.downcase)
    end
  end

  # Indicate whether the item represents a true value.
  #
  # @param [Object] value
  #
  def false?(value)
    case value
      when TrueClass, FalseClass then !value
      when Array, Hash, nil      then false
      else FALSE_VALUES.include?(value.to_s.strip.downcase)
    end
  end

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
    opt   = args.extract_options!
    parts = args.flatten.join('/').lstrip.sub(/[?&\s]+$/, '').split('?')
    url   = parts.shift
    query = parts.join('?').split('&').reject(&:blank?)
    if query.present?
      url << '?' << query.shift unless query.first.include?('=')
      query.map! do |kv|
        k, v = kv.split('=')
        [k.to_sym, CGI.unescape(Array.wrap(v).join('='))]
      end
      opt = query.to_h.merge(opt.symbolize_keys)
    end
    if opt.present?
      url << (url.include?('?') ? '&' : '?') unless url.end_with?('?', '&')
      url << opt.sort.to_h.to_param
    end
    # noinspection RubyYardReturnMatch
    url
  end

  # Strip off the hash elements identified by *keys* to return two hashes:
  # - First, a hash containing only the requested option keys and values.
  # - Second, a copy of the original *hash* without the those keys/values.
  #
  # @param [Hash]          hash
  # @param [Array<Symbol>] keys
  #
  # @return [Array<(Hash, Hash)>]   Matching hash followed by remainder hash.
  #
  def partition_options(hash, *keys)
    keys = keys.flatten.compact.map(&:to_sym).uniq
    return hash.slice(*keys), hash.except(*keys)
  end

  # Return the name of the calling method.
  #
  # @param [Array<String>] call_stack   Default: `#caller(2)`.
  #
  # @return [String]
  #
  def calling_method(call_stack = nil)
    call_stack ||= caller(2)
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fully URL-encode (including transforming '.' to '%2E').
  #
  # @param [String] s
  #
  # @return [String]
  #
  def url_escape(s)
    CGI.escape(s.to_s).gsub(/\./, '%2E')
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
  # @param [Hash]  opt                Passed to #normalized_list; used locally:
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
  #
  # @return [Array<String>]
  #
  def normalized_list(values, **opt)
    opt = opt.merge(sanitize: true) unless opt.key?(:sanitize)
    Array.wrap(values).flat_map { |value|
      case value
        when Hash
          value.map do |k, v|
            case v
              when Hash  then v = hash_string(v, opt)
              when Array then v = array_string(v, opt)
              else            v = v.to_s
            end
            "#{k}: #{v}" if v.present?
          end
        when Array
          array_string(value, opt)
        else
          opt[:sanitize] ? sanitized_string(value) : value.to_s
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
  # @param [ActiveSupport::Buffer, String] text
  # @param [Symbol, Integer, nil]          inflection
  # @param [Integer, nil]                  count
  #
  # @return [ActiveSupport::Buffer, String]
  #
  # @see #INFLECT_SINGULAR
  # @see #INFLECT_PLURAL
  #
  def inflection(text, inflection = nil, count = nil)
    count, inflection = [inflection, nil] if inflection.is_a?(Integer)
    if (count == 1) || INFLECT_SINGULAR.include?(inflection)
      text.singularize
    elsif count.is_a?(Integer) || INFLECT_PLURAL.include?(inflection)
      text.pluralize
    else
      text.to_s.dup
    end
  end

  # Render a camel-case or snake-case string as in "title case" words separated
  # by non-breakable spaces.
  #
  # @param [String, Symbol]       text
  # @param [Integer, Symbol, nil] count
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def labelize(text, count = nil)
    result =
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
        }.compact.join(' ')
    result = ERB::Util.h(result) unless text.html_safe?
    result = inflection(result, count) if count
    result.gsub(/\s/, '&nbsp;').html_safe
  end

  # Remove surrounding quotation marks from a term.
  #
  # @param [ActiveSupport::SafeBuffer, String, Array] term
  #
  # @return [ActiveSupport::SafeBuffer, String]
  #
  def strip_quotes(term)
    result =
      if term.is_a?(Array)
        html_safe = true
        term.map { |t|
          strip_quotes(t).tap { |s| html_safe &&= s.html_safe? }
        }.join(', ')
      else
        html_safe = term.html_safe?
        term.to_s.sub(/^\s*(["'])(.*)\1\s*$/, '\2')
      end
    html_safe ? result.html_safe : result
  end

end

__loading_end(__FILE__)
