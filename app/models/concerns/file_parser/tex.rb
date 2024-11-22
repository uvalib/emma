# app/models/concerns/file_parser/tex.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# TeX file format metadata extractor.
#
class FileParser::Tex < FileParser

  include FileFormat::Tex

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # Metadata extracted from the file format instance.
  #
  # @return [OpenStruct]
  #
  def metadata
    OpenStruct.new # TODO: TeX metadata?
  end

end

__loading_end(__FILE__)
