# app/records/lookup/google_books/record/format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Information about content in a specific format.
#
# @attr [String]  downloadLink
# @attr [String]  acsTokenLink
# @attr [Boolean] isAvailable
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
class Lookup::GoogleBooks::Record::Format < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :downloadLink
    has_one :acsTokenLink
    has_one :isAvailable, Boolean
  end

end

__loading_end(__FILE__)
