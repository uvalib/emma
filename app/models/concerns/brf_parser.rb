# app/models/concerns/brf_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BRF information.
#
class BrfParser < FileParser

  include BrfFormat

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
    OpenStruct.new # TODO: BRF metadata?
  end

end

__loading_end(__FILE__)
