# app/models/concerns/pdf_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'pdf-reader'

# PDF document information.
#
class PdfParser < FileParser

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # metadata
  #
  # @return [*]                       Type is specific to the subclass.
  #
  def metadata
    pdf_reader.metadata
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
    @pdf_reader ||= (PDF::Reader.new(local_path) if local_path)
  end

  # method_missing
  #
  # @param [Symbol] name
  # @param [Array]  args
  #
  # @return [*]
  #
  def method_missing(name, *args)
    if pdf_reader.respond_to?(name)
      __debug_args(binding) { 'via pdf_reader' }
      pdf_reader.send(name, *args)
    elsif pdf_reader.present?
      __debug_args(binding) { 'via pdf_reader.info' }
      pdf_reader.info[name.to_s.camelize.to_sym]
    end
  end

end

__loading_end(__FILE__)
