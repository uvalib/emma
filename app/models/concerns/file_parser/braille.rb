# app/models/concerns/file_parser/braille.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Braille file format metadata extractor.
#
class FileParser::Braille < FileParser

  include FileFormat::Braille

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # Metadata extracted from the file format instance.
  #
  # @return [OpenStruct]
  #
  def metadata
    OpenStruct.new # TODO: Braille metadata?
  end

end

__loading_end(__FILE__)
