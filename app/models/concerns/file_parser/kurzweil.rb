# app/models/concerns/file_parser/kurzweil.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Kurzweil file format metadata extractor.
#
class FileParser::Kurzweil < FileParser

  include FileFormat::Kurzweil

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # metadata
  #
  # @return [OpenStruct]
  #
  def metadata
    OpenStruct.new # TODO: Kurzweil metadata?
  end

end

__loading_end(__FILE__)
