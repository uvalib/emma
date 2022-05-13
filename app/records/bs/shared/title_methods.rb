# app/records/bs/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to catalog titles.
#
module Bs::Shared::TitleMethods

  include Api::Shared::TitleMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # A unique identifier for this catalog title.
  #
  # @return [String]
  #
  def identifier
    bookshareId.to_s
  end

  # ===========================================================================
  # :section: Api::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # Field(s) that may hold the title string.
  #
  # @return [Array<Symbol>]
  #
  def title_fields
    %i[title]
  end

  # Field(s) that may hold the subtitle string.
  #
  # @return [Array<Symbol>]
  #
  def subtitle_fields
    %i[subtitle]
  end

  # Field(s) that may hold content information about the title.
  #
  # @return [Array<Symbol>]
  #
  def contents_fields
    %i[synopsis description]
  end

  # ===========================================================================
  # :section: Api::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # A link to a title's thumbnail image.
  #
  # @return [String]
  # @return [nil]                     If the link was not present.
  #
  def thumbnail_image
    get_link(:thumbnail)
  end

  # A link to a title's cover image if present.
  #
  # @return [String]
  # @return [nil]                     If the link was not present.
  #
  def cover_image
    get_link(:coverimage)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # All artifacts associated with this catalog title.
  #
  # @param [Array<BsFormatType>] types  Default: `BsFormatType#values`
  #
  # @return [Array<String>]
  #
  # == Usage Notes
  # Not all record types which include this module actually have an :artifacts
  # property.
  #
  def artifact_list(*types)
    # noinspection RailsParamDefResolve
    result = try(:artifacts) || []
    result = result.select { |a| types.include?(a.fmt) } if types.present?
    result
  end

  # The number of pages.
  #
  # @return [Integer]
  # @return [nil]                     If the value cannot be determined.
  #
  def page_count
    positive(find_item(:numPages))
  end

  # The number of images.
  #
  # @return [Integer]
  # @return [nil]                     If the value cannot be determined.
  #
  def image_count
    positive(find_item(:numImages))
  end

end

__loading_end(__FILE__)
