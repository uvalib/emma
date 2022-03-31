# app/records/bs/record/reading_position.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::ReadingPosition
#
# @attr [String]                  bookshareId
# @attr [IsoDate]                 dateAdded
# @attr [Bs::Record::Format]      format
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  location
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_position
#
class Bs::Record::ReadingPosition < Bs::Api::Record

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :bookshareId
    has_one   :dateAdded,   IsoDate
    has_one   :format,      Bs::Record::Format
    has_many  :links,       Bs::Record::Link
    has_one   :location
  end

end

__loading_end(__FILE__)
