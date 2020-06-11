# lib/emma/csv.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# CSV utilities.
#
module Emma::Csv

  def self.included(base)
    base.send(:extend, self)
  end

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate data from a CSV file.
  #
  # @param [String, IO, StringIO, IO::Like] src
  # @param [Boolean] allow_raise      Raise exceptions if *true*.
  # @param [Hash]    opt
  #
  # @return [Array<Hash>]
  #
  # == Variations
  #
  # @overload csv_parse(path, allow_raise:, **opt)
  #   @param [String]                 path  Local file path.
  #   @param [Hash]                   opt   Passed to CSV#foreach.
  #
  # @overload csv_parse(io, allow_raise:, **opt)
  #   @param [IO, StringIO, IO::Like] io    IO-like object.
  #   @param [Hash]                   opt   Passed to CSV#parse.
  #
  # == Implementation Notes
  # This addresses an observed issue with CSV#parse not enforcing UTF-8
  # encoding.
  #
  def csv_parse(src, allow_raise: false, **opt)
    opt.reverse_merge!(headers: true)
    src = src.body   if src.respond_to?(:body)
    src = src.string if src.respond_to?(:string)
    if src.is_a?(String)
      # noinspection RubyYardReturnMatch
      CSV.foreach(src, **opt).to_a.map(&:to_h)
    else
      src = src.to_io if src.respond_to?(:to_io)
      CSV.parse(src, **opt).each.map do |row|
        row.to_h.transform_values { |col| force_utf8(col) }
      end
    end
  rescue => e
    Log.info { "#{__method__}: #{e.class}: #{e.message}" }
    raise e if allow_raise
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # force_utf8
  #
  # @param [String, Array, *] item
  #
  # @return [String, Array, *]        Replacement for *item*.
  #
  def force_utf8(item)
    case item
      when String then item.force_encoding('UTF-8')
      when Hash   then item.each.map { |kv| force_utf8(kv) }.to_h
      when Array  then item.map { |v| force_utf8(v) }
      else             item
    end
  end

end

__loading_end(__FILE__)
