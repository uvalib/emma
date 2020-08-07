# app/models/concerns/pdf_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'pdf-reader'

# PDF document information.
#
class PdfParser < FileParser

  include PdfFormat

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # metadata
  #
  # @return [OpenStruct]
  #
  def metadata
    OpenStruct.new(format_metadata(self))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The actual parser object.
  #
  # @return [PDF::Reader]
  # @return [nil]
  #
  def pdf_reader
    @pdf_reader ||= (PDF::Reader.new(file_handle) if file_handle)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # method_missing
  #
  # @param [Symbol] name
  # @param [Array]  args
  #
  # @return [*]
  #
  def method_missing(name, *args)
    if pdf_reader.respond_to?(name)
      __debug_args(binding) { "#{name} [via pdf_reader]" }
      pdf_reader.send(name, *args)
    elsif pdf_reader.present?
      __debug_args(binding) { "#{name} [via pdf_reader.info]" }
      # noinspection RubyNilAnalysis
      pdf_reader.info[name.to_s.camelize.to_sym]
    else
      __debug_args(binding) { "#{name} [FAILED - no pdf_reader]" }
    end
  end

end

__loading_end(__FILE__)
