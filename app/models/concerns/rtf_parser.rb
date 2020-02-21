# app/models/concerns/rtf_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# RTF information.
#
class RtfParser < FileParser

  include RtfFormat

  # ===========================================================================
  # :section: FileParser overrides
  # ===========================================================================

  public

  # metadata
  #
  # @return [OpenStruct]
  #
  # This method overrides:
  # @see FileParser#metadata
  #
  def metadata
    OpenStruct.new # TODO: Rtf metadata?
  end

end

__loading_end(__FILE__)
