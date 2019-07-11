# app/models/api/common/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'sequence_methods'
require 'sanitize'

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
      # Remove the automatically-appended subtitle (in the case of search
      # results entries).
      ti = ti.delete_suffix(st).rstrip.delete_suffix(':') if ti.end_with?(st)
      # Append the subtitle only if it doesn't appear to already be included in
      # the base title itself.
      ti = "#{ti}: #{st}" unless significant(ti).include?(significant(st))
    end
    ti || st || '???'
  end

  # The ISBN if valid.
  #
  # @return [String, nil]
  #
  def isbn
    isbn13 if respond_to?(:isbn13)
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
      next unless respond_to?(date)
      value = send(date).to_s.sub(/^(\d{4}).*/, '\1').to_i
      value unless value.zero?
    }.compact.sort.first
  end

  # Display :synopsis with rudimentary formatting.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def contents
    %i[synopsis description].find do |method|
      next unless respond_to?(method) && (text = send(method)).present?
      text.gsub!(/<br>/, '<br/>')
      text.gsub!(/(<P>)+/, '<br/><br/>')
      text.gsub!(/(?<![&])(#\d{1,5};)/, '&\1')
      return Sanitize.fragment(text).html_safe
    end
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Reduce a string for comparision with another by eliminating characters to
  # ignore for comparision.
  #
  # @param [String]
  #
  # @return [String]
  #
  def significant(string)
    string.to_s.gsub(/[[:space:][:punct:]]/, '').downcase
  end

end

__loading_end(__FILE__)
