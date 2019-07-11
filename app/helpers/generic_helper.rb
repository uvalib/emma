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

  # Indicate whether the item represents a true value.
  #
  # @param [String, Boolean] value
  #
  def true?(value)
    TRUE_VALUES.include?(value.to_s.strip.downcase)
  end

  # Indicate whether the item represents a true value.
  #
  # @param [String, Boolean] value
  #
  def false?(value)
    FALSE_VALUES.include?(value.to_s.strip.downcase)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a URL or partial path.
  #
  # @param [String]    path           URL path (with or without URL options).
  # @param [Hash, nil] opt            URL options to include in the result.
  #
  # @return [String]                  A new path string with *opt* included.
  #
  def make_path(path, **opt)
    result = path.is_a?(String) ? path.dup : path.to_s
    if opt.present?
      result << (result.include?('?') ? '&' : '?')
      result << opt.to_param
    end
    result
  end

  # Strip off the hash elements identified by *keys* to return two hashes:
  # - First, a copy of *original* without the local option keys and values.
  # - Second, a hash containing only the local option keys and values.
  #
  # @param [Hash]          hash
  # @param [Array<Symbol>] keys
  #
  # @return [Array<(Hash, Hash)>]
  #
  def extract_options(hash, *keys)
    keys = keys.flatten.map!(&:to_sym)
    return hash.except(*keys), hash.slice(*keys)
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
  # @param [Hash]      hash
  # @param [Hash, nil] opt
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
  # @param [Array]     array
  # @param [Hash, nil] opt
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
  # @param [Array<String,Symbol,Hash>] values
  # @param [Hash, nil]                 opt
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

end

__loading_end(__FILE__)
