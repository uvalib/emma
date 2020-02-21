# app/models/concerns/tactile_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Tactile information.
#
class TactileParser < FileParser

  include TactileFormat

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
    OpenStruct.new # TODO: Tactile metadata?
  end

end

__loading_end(__FILE__)
