# app/models/concerns/file_parser/brf.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BRF file format metadata extractor.
#
class FileParser::Brf < FileParser

  include FileFormat::Brf

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # Metadata extracted from the file format instance.
  #
  # @return [OpenStruct]
  #
  def metadata
    OpenStruct.new # TODO: BRF metadata?
  end

end

__loading_end(__FILE__)
