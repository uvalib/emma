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

  # Generate data from a CSV file.
  #
  # @param [String, IO, StringIO, IO::Like] src
  # @param [Boolean] no_raise         If *false*, re-raise exceptions.
  # @param [Hash]    opt
  #
  # @return [Array<Hash>]
  # @return [nil]                     Only if *no_raise* is *true*.
  #
  #--
  # == Variations
  #++
  #
  # @overload csv_parse(path, no_raise:, **opt)
  #   @param [String]                 path      Local file path.
  #   @param [Boolean]                no_raise
  #   @param [Hash]                   opt       Passed to CSV#foreach.
  #
  # @overload csv_parse(io, no_raise:, **opt)
  #   @param [IO, StringIO, IO::Like] io        IO-like object.
  #   @param [Boolean]                no_raise
  #   @param [Hash]                   opt       Passed to CSV#parse.
  #
  # == Implementation Notes
  # This addresses an observed issue with CSV#parse not enforcing UTF-8
  # encoding.
  #
  def csv_parse(src, no_raise: true, **opt)
    opt.reverse_merge!(headers: true)
    src = src.body   if src.respond_to?(:body)
    src = src.string if src.respond_to?(:string)
    if src.is_a?(String)
      # noinspection RubyMismatchedArgumentType
      CSV.foreach(src, **opt).to_a.map(&:to_h) if src.present?
    else
      src = src.to_io if src.respond_to?(:to_io)
      # noinspection RubyMismatchedArgumentType, RubyNilAnalysis
      CSV.parse(src, **opt).each.map do |row|
        row.to_h.transform_values { |col| force_utf8(col) }
      end
    end
  rescue => error
    Log.info { "#{__method__}: #{error.class}: #{error.message}" }
    raise error unless no_raise
    re_raise_if_internal_exception(error)
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
