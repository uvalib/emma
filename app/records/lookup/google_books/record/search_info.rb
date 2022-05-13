# app/records/lookup/google_books/record/search_info.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search result information related to this volume.
#
# @attr [String] textSnippet
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
#--
# noinspection LongLine
#++
class Lookup::GoogleBooks::Record::SearchInfo < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :textSnippet
  end

end

__loading_end(__FILE__)
