# app/models/concerns/kurzweil_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Kurzweil information.
#
class KurzweilParser < FileParser

  include KurzweilFormat

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
