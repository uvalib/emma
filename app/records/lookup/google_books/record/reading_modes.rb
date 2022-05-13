# app/records/lookup/google_books/record/reading_modes.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Reading modes.
#
# @attr [Boolean] text
# @attr [Boolean] image
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
#--
# noinspection LongLine
#++
class Lookup::GoogleBooks::Record::ReadingModes < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :text,  Boolean
    has_one :image, Boolean
  end

end

__loading_end(__FILE__)
