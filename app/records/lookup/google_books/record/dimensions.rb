# app/records/lookup/google_books/record/dimensions.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Physical dimensions of this volume (in centimeters).
#
# @attr [String] height
# @attr [String] width
# @attr [String] thickness
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
#--
# noinspection LongLine
#++
class Lookup::GoogleBooks::Record::Dimensions < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :height
    has_one :width
    has_one :thickness
  end

end

__loading_end(__FILE__)
