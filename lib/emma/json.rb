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
  # @param [Boolean] log           If *false*, do not log errors.
  # @param [Boolean] no_raise      If *false*, re-raise exceptions.
  # @param [Hash]    opt           Passed to MultiJson#load.
  #
  # @raise [RuntimeError]          If *arg* does not resolve to Hash or String.
  # @raise [MultiJson::ParseError] If *arg* failed to parse and !*no_raise*.
  #
  # @return [nil]                  If *arg* failed to parse and *no_raise*.
  # @return [Array<Hash>]
  # @return [Hash]
  #
  #--
  # == Variations
  #++
  #
  # @overload json_parse(hash = nil, log: true, no_raise: true, **)
  #   If *arg* is already a Hash, a copy of it is returned.
  #   @param [Hash, nil] hash
  #   @param [Boolean]   log
  #   @param [Boolean]   no_raise
  #   @return [Hash, nil]
  #
  # @overload json_parse(json, log: true, no_raise: true, **opt)
  #   If *arg* is a String it is assumed to be JSON format (although renderings
  #   of Ruby hashes are accommodated by converting "=>" to ":").
  #   @param [String]  json
  #   @param [Boolean] log
  #   @param [Boolean] no_raise
  #   @param [Hash]    opt
  #   @return [Hash, Array<Hash>, nil]
  #
  # @overload json_parse(io, log: true, no_raise: true, **opt)
  #   If *arg* is IO-like, its contents are read and parsed as JSON.
  #   @param [IO, StringIO, IO::Like] io
  #   @param [Boolean]                log
  #   @param [Boolean]                no_raise
  #   @param [Hash]                   opt
  #   @return [Hash, Array<Hash>, nil]
  #
  # == Usage Notes
  # If opt[:symbolize_keys] is explicitly *false* then this causes all result
  # keys to be converted to strings.
  #
  #--
  # noinspection RubyNilAnalysis, RubyMismatchedReturnType
  #++
  def json_parse(arg, log: true, no_raise: true, **opt)
    str = false?(opt[:symbolize_keys])
    sym = opt[:symbolize_keys] = !str
    arg = arg.to_io  if arg.respond_to?(:to_io)
    arg = arg.read   if arg.respond_to?(:read)
    arg = arg.body   if arg.respond_to?(:body)
    arg = arg.string if arg.respond_to?(:string)
    case arg
      when nil          then return
      when Hash         then res = sym ? arg.deep_symbolize_keys : arg
      when /\A\s*[\[{]/ then res = MultiJson.load(arg, opt)
      when String       then res = log.presence
      else                   raise "#{arg.class} unexpected"
    end
    # noinspection RubyCaseWithoutElseBlockInspection
    case res
      when Hash  then str ? res.deep_stringify_keys : res
      when Array then res.map { |v| str && v.try(:deep_stringify_keys) || v }
      when log   then Log.info { "#{__method__}: non-JSON: #{arg.inspect}" }
    end
  rescue => error
    Log.info { "#{__method__}: #{error.class}: #{error.message}" } if log
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
  # @param [String, Hash, *] arg
  # @param [Boolean] no_raise         If *false*, re-raise exceptions.
  # @param [Boolean] align_values
  # @param [Boolean] ruby_keys        Remove surrounding quotes from keys.
  #
  # @raise [MultiJson::ParseError]
  # @raise [RuntimeError]
  #
  # @return [String]
  #
  # @see #json_parse
  #
  # == Usage Notes
  # An HTML element can show the lines as they are generated if it has style
  # "white-space: pre;".
  #
  def pretty_json(arg, no_raise: true, align_values: true, ruby_keys: true)
    source  = json_parse(arg, symbolize_keys: false, no_raise: false)
    result  = MultiJson.dump(source, pretty: true)
    key_max = align_values
    key_max &&=
      result.gsub(/^\s*"/, '').gsub(/": .*$/, '').split("\n").map(&:size).max
    if align_values || ruby_keys
      result.gsub!(/^(\s*)"([^"]+?)":\s*(.*)$/) do
        space = $1
        key   = $2.to_s
        val   = $3.to_s
        align = (' ' * (key_max - key.size) if key_max)
        key   = %Q("#{key}") unless ruby_keys
        val   = 'nil'        if ruby_keys && val.match?(/null,?/)
        "#{space}#{key}: #{align}#{val}"
      end
    end
    result
  rescue => error
    Log.debug { "#{__method__}: #{error.class}: #{error.message}" }
    raise error unless no_raise
    re_raise_if_internal_exception(error)
    arg.pretty_inspect
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
