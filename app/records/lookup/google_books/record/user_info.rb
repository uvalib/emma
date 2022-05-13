# app/records/lookup/google_books/record/user_info.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# User specific information related to this volume. (e.g. page this user last
# read or whether they purchased this book).
#
# @attr [Hash]     review
# @attr [String]   readingPosition
# @attr [Boolean]  isPurchased
# @attr [DateTime] updated
# @attr [Boolean]  isPreordered
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
class Lookup::GoogleBooks::Record::UserInfo < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :review,          Hash
    has_one :readingPosition
    has_one :isPurchased,     Boolean
    has_one :updated,         DateTime
    has_one :isPreordered,    Boolean
  end

end

__loading_end(__FILE__)
