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

  # The default :symbol converter transforms to lowercase first, which is
  # problematic for headers that are intended to match database field names.
  # (While the database *column* names are technically case-insensitive, many
  # parts of the code expect to access values by *field* name.)

  CSV::HeaderConverters[:pure_symbol] ||=
    lambda do |hc|
      hc.encode(CSV::ConverterEncoding)
        .strip
        .gsub(/\s+/, '_')
        .remove!(/\W/)
        .to_sym
    end

  # Default CSV options used by #csv_parse.
  #
  # @type [Hash]
  #
  # @see CSV#DEFAULT_OPTIONS
  #
  CSV_DEFAULTS = {
    converters:        nil,             # NOTE: values will be String or nil.
    empty_value:       nil,             # Blank column values reported as nil.
    header_converters: %i[pure_symbol],
    headers:           true,            # Data must have column headers.
    strip:             true,
    skip_blanks:       true,            # Input lines without data are ignored.
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate data from CSV input.
  #
  # @param [String, IO, StringIO, IO::Like, nil] arg
  # @param [Boolean] no_empty         If *false*, allow data will all nils.
  # @param [Boolean] utf8
  # @param [Boolean] fatal            If *true*, re-raise exceptions.
  # @param [Hash]    opt              Passed to CSV#parse.
  #
  # @return [Array<Hash>]
  # @return [nil]                     Only if *fatal* is *false*.
  #
  # === Usage Notes
  # The argument is expected to either be the literal data or an object like an
  # IO or StringIO through which the data can be acquired.  To parse the
  # content located at a URI (web page or local file path) read the contents
  # first or pass in an open file handle.
  #
  # === Implementation Notes
  # This addresses an observed issue with CSV#parse not enforcing UTF-8
  # encoding.  NOTE: This might not be necessary any longer though.
  #
  def csv_parse(arg, no_empty: true, utf8: true, fatal: false, **opt)
    return if arg.nil? || arg.is_a?(Puma::NullIO)
    CSV.parse(arg, **CSV_DEFAULTS, **opt).map { |row|
      row = row.to_h
      next if no_empty && row.values.all?(&:nil?)
      utf8 ? row.transform_values! { force_utf8(_1) } : row
    }.compact
  rescue => error
    Log.info { "#{__method__}: #{error.class}: #{error.message}" }
    re_raise_if_internal_exception(error)
    raise error if fatal
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Force UTF-8 encoding on to the string parts of *item*.
  #
  # @param [any, nil] item            String, Array, Hash
  #
  # @return [String, Array, Hash, any, nil]  Replacement for *item*.
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
    base.extend(self)
  end

end

__loading_end(__FILE__)
