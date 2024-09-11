# app/models/concerns/file_parser/html.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HTML file format metadata extractor.
#
class FileParser::Html < FileParser

  include FileFormat::Html

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # metadata
  #
  # @return [OpenStruct]
  #
  def metadata
    OpenStruct.new # TODO: HTML metadata?
  end

end

__loading_end(__FILE__)
