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
  # @param [String, Hash, IO, StringIO, IO::Like, nil] arg
  # @param [Boolean] log           If *false*, do not log errors.
  # @param [Boolean] fatal         If *true*, re-raise exceptions.
  # @param [Hash]    opt           Passed to MultiJson#load.
  #
  # @raise [RuntimeError]          If *arg* does not resolve to Hash or String.
  # @raise [MultiJson::ParseError] If *arg* failed to parse and *fatal*.
  #
  # @return [nil]                  If *arg* failed to parse and not *fatal*.
  # @return [Hash]
  # @return [Array<Hash>]
  #
  #--
  # === Variations
  #++
  #
  # @overload json_parse(hash = nil, log: true, fatal: false, **)
  #   If *arg* is already a Hash, a copy of it is returned.
  #   @param [Hash, nil] hash
  #   @param [Boolean]   log
  #   @param [Boolean]   fatal
  #   @param [Hash]      opt
  #   @return [Hash, nil]
  #
  # @overload json_parse(json, log: true, fatal: false, **opt)
  #   If *arg* is a String it is assumed to be JSON format (although renderings
  #   of Ruby hashes are accommodated by converting "=>" to ":").
  #   @param [String]    json
  #   @param [Boolean]   log
  #   @param [Boolean]   fatal
  #   @param [Hash]      opt
  #   @return [Hash, Array<Hash>, nil]
  #
  # @overload json_parse(io, log: true, fatal: false, **opt)
  #   If *arg* is IO-like, its contents are read and parsed as JSON.
  #   @param [IO, StringIO, IO::Like] io
  #   @param [Boolean]                log
  #   @param [Boolean]                fatal
  #   @param [Hash]                   opt
  #   @return [Hash, Array<Hash>, nil]
  #
  # === Usage Notes
  # If opt[:symbolize_keys] is explicitly *false* then this causes all result
  # keys to be converted to strings.
  #
  def json_parse(arg, log: true, fatal: false, **opt)
    return if arg.nil?
    str = false?(opt[:symbolize_keys])
    sym = opt[:symbolize_keys] = !str
    case arg
      when Hash
        res = sym ? arg.deep_symbolize_keys : arg
      when IO, StringIO, IO::Like, /\A\s*[\[{]/
        res = MultiJson.load(arg, opt)
      when String
        res = log.presence
      else
        raise "#{arg.class} unexpected"
    end
    # noinspection RubyMismatchedReturnType
    case res
      when Hash  then str ? res.deep_stringify_keys : res
      when Array then res.map { |v| str && v.try(:deep_stringify_keys) || v }
      when log   then Log.info { "#{__method__}: non-JSON: #{arg.inspect}" }
    end
  rescue => error
    Log.info { "#{__method__}: #{error.class}: #{error.message}" } if log
    re_raise_if_internal_exception(error)
    raise error if fatal
  end

  # Attempt to interpret *arg* as JSON if it is a string.
  #
  # @param [any, nil] arg
  # @param [any]      default         On parse failure, return this if provided
  #                                     (or return *arg* otherwise).
  # @param [Hash]     opt             Passed to #json_parse.
  #
  # @return [Hash, Array<Hash>, any, nil]
  #
  def safe_json_parse(arg, default: :original, **opt)
    json_parse(arg, **opt) || ((default == :original) ? arg : default)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # json_render
  #
  # @param [String, Hash, IO, StringIO, IO::Like, nil] arg
  # @param [Boolean] align_values
  # @param [Boolean] ruby_keys        Remove surrounding quotes from keys.
  # @param [Boolean] fatal            If *true*, re-raise exceptions.
  # @param [Boolean] log              If *false*, no debug logging.
  #
  # @raise [MultiJson::ParseError]
  # @raise [RuntimeError]
  #
  # @return [String]
  #
  # @see #pretty_json
  #
  def json_render(
    arg,
    align_values: false,
    ruby_keys:    false,
    fatal:        false,
    log:          true
  )
    option = { align_values: align_values, ruby_keys: ruby_keys, log: log }
    result = pretty_json(arg, fatal: true, **option)
    result.gsub!(/\n/, ' ') unless align_values
    result
  rescue => error
    Log.debug { "#{__method__}: #{error.class}: #{error.message}" } if log
    re_raise_if_internal_exception(error)
    raise error if fatal
    arg.inspect
  end

  # pretty_json
  #
  # @param [any, nil] arg
  # @param [Boolean]  align_values
  # @param [Boolean]  ruby_keys       Remove surrounding quotes from keys.
  # @param [Boolean]  fatal           If *true*, re-raise exceptions.
  # @param [Boolean]  log             If *false*, no debug logging.
  #
  # @raise [MultiJson::ParseError]
  # @raise [RuntimeError]
  #
  # @return [String]
  #
  # @see #json_parse
  #
  # === Usage Notes
  # An HTML element can show the lines as they are generated if it has style
  # "white-space: pre;".
  #
  def pretty_json(
    arg,
    align_values: true,
    ruby_keys:    true,
    fatal:        false,
    log:          true
  )
    source = json_parse(arg, symbolize_keys: false, fatal: true, log: log)
    result = MultiJson.dump(source, pretty: true)
    if align_values || ruby_keys
      keys    = (result.split("\n") if align_values)
      keys  &&= keys.map! { |v| v.sub!(/^\s*"(\w+)": .*$/, '\1')&.size || 0 }
      key_max = keys&.max
      result.gsub!(/^(\s*)"([^"]+?)":\s*(.*)$/) do
        space = $1
        key   = $2.to_s
        val   = $3.to_s
        align = key_max && (n = positive(key_max - key.size)) && (' ' * n)
        key   = quote(key)            unless ruby_keys
        val.sub!(/null(,?)/, 'nil\1') if ruby_keys
        "#{space}#{key}: #{align}#{val}"
      end
    end
    result
  rescue => error
    Log.debug { "#{__method__}: #{error.class}: #{error.message}" } if log
    re_raise_if_internal_exception(error)
    raise error if fatal
    arg.pretty_inspect
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Recreate a Hash from Hash#to_s output.
  #
  # @param [String] arg
  #
  # @return [Array<Hash>, Hash, nil]
  #
  def hash_parse(arg)
    arg = hash_inspect_to_json(arg) if arg && !arg.is_a?(Hash)
    json_parse(arg) if arg
  end

  # Translate from Hash#to_s output to JSON.
  #
  # @param [any, nil] arg
  #
  # @return [String]
  #
  def hash_inspect_to_json(arg)
    json = arg.is_a?(String) ? arg.dup : arg.to_s
    json.gsub!(/(?<=^|\[|{|,)(\s*)'([^']+)' *(:|=>) */,     '\1"\2": ')
    json.gsub!(/(?<=^|\[|{|,)(\s*)"([^"]+)" *(:|=>) */,     '\1"\2": ')
    json.gsub!(/(?<=^|\[|{|,)(\s*)([^"\[{,\s]+) *(:|=>) */, '\1"\2": ')
    json.gsub!(/(?<=[:,])(\s*)'([^']+)'\s*(?=[\]},])/,      '\1"\2"')
    json.gsub!(/(?<=[:,])(\s*)nil\s*(?=[\]},])/,            '\1null')
    json
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # hash_render
  #
  # @param [String, Hash, IO, StringIO, IO::Like, nil] arg
  # @param [Boolean] fatal            If *true*, re-raise exceptions.
  # @param [Hash]    opt              Passed to #json_render.
  #
  # @raise [MultiJson::ParseError]
  # @raise [RuntimeError]
  #
  # @return [String]
  #
  # @see #json_render
  #
  def hash_render(arg, fatal: false, **opt)
    opt[:ruby_keys] = true unless opt.key?(:ruby_keys)
    json_render(arg, fatal: true, **opt)
  rescue => error
    Log.debug { "#{__method__}: #{error.class}: #{error.message}" }
    re_raise_if_internal_exception(error)
    raise error if fatal
    arg.inspect
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
