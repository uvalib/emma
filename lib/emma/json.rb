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

  # Covert a JSON string into a Hash.
  #
  # @param [String, Hash] arg
  # @param [Boolean] raise_exception  If *true* allow exceptions to be raised.
  #
  # @return [Hash]
  # @return [nil]                     If *arg* failed to parse.
  #
  # @raise [MultiJson::ParseError]    If *arg* failed to parse and
  #                                     *raise_exception* is *true*.
  #
  # noinspection RubyYardReturnMatch
  def json_parse(arg, raise_exception: false, **opt)
    if arg.is_a?(Hash)
      arg
    elsif arg.is_a?(String)
      arg = arg.gsub(/=>/, ':')
      opt.reverse_merge!(symbolize_keys: true)
      MultiJson.load(arg, opt)
    else
      raise ArgumentError
    end

  rescue => e
    raise e if raise_exception
    nil
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
  # @param [Boolean] raise_exception  If *true* allow exceptions to be raised.
  # @param [Boolean] ruby_keys        Remove surrounding quotes from keys.
  #
  # @return [String]
  #
  # @raise [ArgumentError]            If *arg* was neither a String nor Hash.
  # @raise [MultiJson::ParseError]    If *arg* failed to parse.
  #
  # == Usage Notes
  # An HTML element can show the lines as they are generated if it has style
  # "white-space: pre;".
  #
  def pretty_json(value, raise_exception: false, ruby_keys: true)
    case value
      when String then value = json_parse(value, raise_exception: true)
      when Hash   then value = value.deep_stringify_keys
      else             raise ArgumentError
    end
    result = MultiJson.dump(value, pretty: true)
    result.gsub!(/^(\s*)"([^"]+?)":/, '\1\2:') if ruby_keys
    result

  rescue => e
    Log.debug { "#{__method__}: #{e.class}: #{e.message}" }
    raise e if raise_exception
    value.pretty_inspect
  end

end

__loading_end(__FILE__)
