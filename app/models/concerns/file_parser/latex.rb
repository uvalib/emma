# app/models/concerns/file_parser/latex.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LaTeX file format metadata extractor.
#
class FileParser::Latex < FileParser

  include FileFormat::Latex

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # metadata
  #
  # @return [OpenStruct]
  #
  def metadata
    OpenStruct.new # TODO: LaTeX metadata?
  end

end

__loading_end(__FILE__)
