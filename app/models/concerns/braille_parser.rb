# app/models/concerns/braille_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Braille information.
#
class BrailleParser < FileParser

  include BrailleFormat

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
    OpenStruct.new # TODO: Braille metadata?
  end

end

__loading_end(__FILE__)
