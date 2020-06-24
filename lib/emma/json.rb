# lib/emma/json.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'multi_json'

# JSON utilities.
#
module Emma::Json

  def self.included(base)
    base.send(:extend, self)
  end

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
  # @raise [StandardError]         If *arg* is not parseable.
  # @raise [MultiJson::ParseError] If *arg* failed to parse and !*no_raise*.
  #
  # @return [nil]                  If *arg* failed to parse and *no_raise*.
  # @return [Hash]
  # @return [Array<Hash,Array,String>]
  #
  # == Variations
  #
  # @overload json_parse(hash = nil)
  #   If *arg* is already a Hash, a copy of it is returned.
  #   @param [Hash, nil] hash
  #
  # @overload json_parse(json, no_raise:, **opt)
  #   If *arg* is a String it is assumed to be JSON format (although renderings
  #   of Ruby hashes are accommodated by converting "=>" to ":").
  #   @param [String] json
  #
  # @overload json_parse(io, no_raise:, **opt)
  #   If *arg* is IO-like, its contents are read and parsed as JSON.
  #   @param [IO, StringIO, IO::Like] io
  #
  #--
  # noinspection RubyYardReturnMatch
  #++
  def json_parse(arg, no_raise: true, **opt)
    return if arg.blank?
    arg = arg.body   if arg.respond_to?(:body)
    arg = arg.string if arg.respond_to?(:string)
    if arg.is_a?(Hash)
      arg.deep_symbolize_keys
    elsif arg.respond_to?(:read)
      json_parse(arg.read, no_raise: no_raise, **opt)
    elsif arg.respond_to?(:to_io)
      json_parse(arg.to_io.read, no_raise: no_raise, **opt)
    elsif arg.is_a?(String)
      arg = arg.gsub(/=>/, ':')
      opt.reverse_merge!(symbolize_keys: true)
      MultiJson.load(arg, opt)
    else
      Log.error { "#{__method__}: #{arg.class} unexpected: #{arg.inspect}" }
      raise "#{__method__}: #{arg.class} unexpected"
    end
  rescue => error
    raise error unless no_raise
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
    # noinspection RubyYardReturnMatch
    json_parse(arg, opt) || ((default == :original) ? arg : default)
  end

  # pretty_json
  #
  # @param [String, Hash, *] value
  # @param [Boolean] no_raise         If *false*, re-raise exceptions.
  # @param [Boolean] ruby_keys        Remove surrounding quotes from keys.
  #
  # @raise [MultiJson::ParseError]    If *arg* failed to parse.
  # @raise [StandardError]            If *value* is not a String or Hash.
  #
  # @return [String]
  #
  # == Usage Notes
  # An HTML element can show the lines as they are generated if it has style
  # "white-space: pre;".
  #
  def pretty_json(value, no_raise: true, ruby_keys: true)
    case value
      when String then value = json_parse(value, no_raise: false)
      when Hash   then value = value.deep_stringify_keys
      else             raise "#{value.class} unexpected"
    end
    result = MultiJson.dump(value, pretty: true)
    result.gsub!(/^(\s*)"([^"]+?)":/, '\1\2:') if ruby_keys
    result
  rescue => error
    Log.debug { "#{__method__}: #{error.class}: #{error.message}" }
    raise error unless no_raise
    value.pretty_inspect
  end

end

__loading_end(__FILE__)
