# lib/emma/csv.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'csv'

# CSV utilities.
#
module Emma::Csv

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default CSV options used by #csv_parse.
  #
  # @type [Hash{Symbol=>*}]
  #
  # @see CSV#DEFAULT_OPTIONS
  #
  CSV_DEFAULTS = {
    converters:        :all,
    empty_value:       nil,
    header_converters: :symbol,
    headers:           true,
    strip:             true,
    skip_blanks:       true,
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate data from CSV input.
  #
  # @param [String, IO, StringIO, IO::Like, nil] arg
  # @param [Boolean] no_raise         If *false*, re-raise exceptions.
  # @param [Boolean] utf8
  # @param [Hash]    opt
  #
  # @return [Array<Hash>]
  # @return [nil]                     Only if *no_raise* is *true*.
  #
  # == Usage Notes
  # The argument is expected to either be the literal data or an object like an
  # IO or StringIO through which the data can be acquired.  To parse the
  # content located at a URI (web page or local file path) read the contents
  # first or pass in an open file handle.
  #
  # == Implementation Notes
  # This addresses an observed issue with CSV#parse not enforcing UTF-8
  # encoding.  NOTE: This might not be necessary any longer though.
  #
  def csv_parse(arg, no_raise: true, utf8: true, **opt)
    return if arg.nil? || arg.is_a?(Puma::NullIO)
    CSV.parse(arg, **CSV_DEFAULTS, **opt).map(&:to_h).tap do |rows|
      rows.each { |row| row.transform_values! { |v| force_utf8(v) } } if utf8
    end
  rescue => error
    Log.info { "#{__method__}: #{error.class}: #{error.message}" }
    re_raise_if_internal_exception(error)
    raise error unless no_raise
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # force_utf8
  #
  # @param [String, Array, Hash, Any] item
  #
  # @return [String, Array, Hash, Any]  Replacement for *item*.
  #
  def force_utf8(item)
    case item
      when String then item.force_encoding('UTF-8')
      when Hash   then item.each.map { |kv| force_utf8(kv) }.to_h
      when Array  then item.map { |v| force_utf8(v) }
      else             item
    end
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
