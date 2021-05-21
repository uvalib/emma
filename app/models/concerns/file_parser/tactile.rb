# app/models/concerns/file_parser/tactile.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Tactile file format metadata extractor.
#
class FileParser::Tactile < FileParser

  include FileFormat::Tactile

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # metadata
  #
  # @return [OpenStruct]
  #
  def metadata
    OpenStruct.new # TODO: Tactile metadata?
  end

end

__loading_end(__FILE__)
