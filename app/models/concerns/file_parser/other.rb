# app/models/concerns/file_parser/other.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata extractor for a non-specific format.
#
class FileParser::Other < FileParser

  include FileFormat::Other

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # metadata
  #
  # @return [OpenStruct]
  #
  def metadata
    OpenStruct.new
  end

end

__loading_end(__FILE__)
