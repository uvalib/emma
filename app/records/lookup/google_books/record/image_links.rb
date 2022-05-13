# app/records/lookup/google_books/record/image_links.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A list of image links for all the sizes that are available.
#
# @attr [String] thumbnail
# @attr [String] small
# @attr [String] medium
# @attr [String] large
# @attr [String] smallThumbnail
# @attr [String] extraLarge
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
#--
# noinspection LongLine
#++
class Lookup::GoogleBooks::Record::ImageLinks < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :thumbnail
    has_one :small
    has_one :medium
    has_one :large
    has_one :smallThumbnail
    has_one :extraLarge
  end

end

__loading_end(__FILE__)
