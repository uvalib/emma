# app/models/concerns/file_parser/rtf.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# RTF file format metadata extractor.
#
class FileParser::Rtf < FileParser

  include FileFormat::Rtf

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # Metadata extracted from the file format instance.
  #
  # @return [OpenStruct]
  #
  def metadata
    OpenStruct.new # TODO: Rtf metadata?
  end

end

__loading_end(__FILE__)
