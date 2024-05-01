# lib/emma/common/string_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'cgi'
require 'sanitize'

module Emma::Common::StringMethods

  extend self

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
  # @param [Hash]           opt       Passed to Sanitize#fragment.
  #
  # @return [String]
  #
  def sanitized_string(string, **opt)
    text = Sanitize.fragment(string.to_s, **opt)
    text = CGI.unescapeHTML(text)
    text.gsub(/&nbsp;/, ' ')
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
          value = sanitized_string(value) if value.is_a?(String) && sanitize
          value = value.squish            if value.is_a?(String)
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  HEX = '[a-fA-F0-9]'

  # @private
  UUID_FORMAT = /\A#{HEX}{8}-#{HEX}{4}-#{HEX}{4}-#{HEX}{4}-#{HEX}{12}\z/.freeze

  # Indicate whether item is a UUID value.
  #
  # @param [any, nil] item
  #
  def uuid?(item)
    item.to_s.match?(UUID_FORMAT)
  end

end

__loading_end(__FILE__)
