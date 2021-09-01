# lib/emma/json.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'multi_json'

# JSON utilities.
#
module Emma::Json

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Covert JSON into a Hash.
  #
  # @param [Hash, String, IO, StringIO, IO::Like, nil] arg
  # @param [Boolean] no_raise      If *false*, re-raise exceptions.
  # @param [Hash]    opt           Passed to MultiJson#load.
  #
  # @raise [RuntimeError]          If *arg* is not parseable.
  # @raise [MultiJson::ParseError] If *arg* failed to parse and !*no_raise*.
  #
  # @return [nil]                  If *arg* failed to parse and *no_raise*.
  # @return [Hash]
  # @return [Array<Hash,Array,String>]
  #
  # == Variations
  #
  # @overload json_parse(hash = nil, **opt)
  #   If *arg* is already a Hash, a copy of it is returned.
  #   @param [Hash, nil] hash
  #   @param [Hash]      opt
  #
  # @overload json_parse(json, no_raise:, **opt)
  #   If *arg* is a String it is assumed to be JSON format (although renderings
  #   of Ruby hashes are accommodated by converting "=>" to ":").
  #   @param [String]  json
  #   @param [Boolean] no_raise
  #   @param [Hash]    opt
  #
  # @overload json_parse(io, no_raise:, **opt)
  #   If *arg* is IO-like, its contents are read and parsed as JSON.
  #   @param [IO, StringIO, IO::Like] io
  #   @param [Boolean]                no_raise
  #   @param [Hash]                   opt
  #
  # == Usage Notes
  # If opt[:symbolize_keys] is explicitly *false* then this causes all result
  # keys to be converted to strings.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def json_parse(arg, no_raise: true, **opt)
    return if arg.blank?
    str = false?(opt[:symbolize_keys])
    sym = !opt.key?(:symbolize_keys) || true?(opt[:symbolize_keys])
    opt[:symbolize_keys] = sym
    arg = arg.to_io  if arg.respond_to?(:to_io)
    arg = arg.read   if arg.respond_to?(:read)
    arg = arg.body   if arg.respond_to?(:body)
    arg = arg.string if arg.respond_to?(:string)
    case arg
      when Hash   then res = sym ? arg.deep_symbolize_keys : arg
      when String then res = MultiJson.load(arg, opt)
      else             raise "#{arg.class} unexpected"
    end
    str ? res.deep_stringify_keys : res
  rescue => error
    Log.info { "#{__method__}: #{error.class}: #{error.message}" }
    raise error unless no_raise
    re_raise_if_internal_exception(error)
  end

  # Attempt to interpret *arg* as JSON if it is a string.
  #
  # @param [String, *] arg
  # @param [*]         default        On parse failure, return this if provided
  #                                     (or return *arg* otherwise).
  # @param [Hash]      opt            Passed to #json_parse.
  #
  # @return [Hash, *]
  #
  def safe_json_parse(arg, default: :original, **opt)
    # noinspection RubyMismatchedReturnType
    json_parse(arg, **opt) || ((default == :original) ? arg : default)
  end

  # pretty_json
  #
  # @param [String, Hash, *] value
  # @param [Boolean] no_raise         If *false*, re-raise exceptions.
  # @param [Boolean] align_values
  # @param [Boolean] ruby_keys        Remove surrounding quotes from keys.
  #
  # @raise [MultiJson::ParseError]    If *arg* failed to parse.
  # @raise [RuntimeError]             If *value* is not a String or Hash.
  #
  # @return [String]
  #
  # == Usage Notes
  # An HTML element can show the lines as they are generated if it has style
  # "white-space: pre;".
  #
  def pretty_json(value, no_raise: true, align_values: true, ruby_keys: true)
    case value
      when String then value = json_parse(value, no_raise: false)
      when Hash   then value = value.deep_stringify_keys
      else             raise "#{value.class} unexpected"
    end
    result = MultiJson.dump(value, pretty: true)
    max_key_size =
      if align_values
        result.gsub(/^\s*"/, '').gsub(/": .*$/, '').split("\n").map(&:size).max
      end
    if align_values || ruby_keys
      result.gsub!(/^(\s*)"([^"]+?)":\s*(.*)$/) do
        space = $1
        key   = $2.to_s
        val   = $3
        align = (' ' * (max_key_size - key.size) if align_values)
        key   = %Q("#{$2}") unless ruby_keys
        val   = 'nil'       if ruby_keys && val.match?(/null,?/)
        "#{space}#{key}: #{align}#{val}"
      end
    end
    result
  rescue => error
    Log.debug { "#{__method__}: #{error.class}: #{error.message}" }
    raise error unless no_raise
    re_raise_if_internal_exception(error)
    value.pretty_inspect
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
