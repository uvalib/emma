# app/models/concerns/file_parser/pdf.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'pdf-reader'

# PDF file format metadata extractor.
#
class FileParser::Pdf < FileParser

  include FileFormat::Pdf

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
    @pdf_reader ||=
      (f = file_handle&.handle || filename).presence && PDF::Reader.new(f)
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
  # @return [any, nil]
  #
  def method_missing(name, *args)
    if pdf_reader.respond_to?(name)
      __debug_items(binding) { "#{name} [via pdf_reader]" }
      pdf_reader.send(name, *args)
    elsif pdf_reader.present?
      __debug_items(binding) { "#{name} [via pdf_reader.info]" }
      pdf_reader.info[name.to_s.camelize.to_sym]
    else
      __debug_items(binding) { "#{name} [FAILED - no pdf_reader]" }
    end
  rescue => e
    Log.error do
      "FileParser::Pdf: method_missing: #{e.class} #{e.message} - stack:\n" +
        caller.pretty_inspect
    end
  end

end

__loading_end(__FILE__)
