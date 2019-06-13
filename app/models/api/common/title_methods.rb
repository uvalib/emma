# app/models/api/common/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'sequence_methods'

# Methods mixed in to record elements related to catalog titles.
#
module Api::Common::TitleMethods

  include Api::Common::SequenceMethods

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Convert object to string.
  #
  # @return [String]
  #
  def to_s
    label
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the item.
  #
  # @return [String]
  #
  def label
    full_title
  end

  # A unique identifier for this catalog title.
  #
  # @return [String]
  #
  def identifier
    bookshareId.to_s
  end

  # The title and subtitle of this catalog title.
  #
  # @return [String]
  #
  def full_title
    ti = title.to_s.presence
    st = respond_to?(:subtitle) && subtitle.to_s.presence
    if ti && st
      st = ": #{st}"
      ti.include?(st) ? ti : (ti + st)
    else
      ti || st || '???'
    end
  end

  # The number of pages if valid.
  #
  # @return [Integer, nil]
  #
  def page_count
    count = respond_to?(:numPages) ? numPages.to_i : 0
    count if count > 0
  end

  # The number of images if valid.
  #
  # @return [Integer, nil]
  #
  def image_count
    count = respond_to?(:numImages) ? numImages.to_i : 0
    count if count > 0
  end

  # Return the year of publication (from :publishDate or :copyrightDate,
  # whichever is earlier).
  #
  # @return [Integer, nil]
  #
  def year
    %i[copyrightDate publishDate].map { |date|
      send(date).to_s.sub(/^(\d{4}).*/, '\1').to_i if respond_to?(date)
    }.compact.sort.first
  end

  # Return a link to a title's thumbnail image if present.
  #
  # @return [String, nil]
  #
  def thumbnail_image
    get_link('thumbnail')
  end

  # Return a link to a title's cover image if present.
  #
  # @return [String, nil]
  #
  def cover_image
    get_link('coverimage')
  end

end

__loading_end(__FILE__)
