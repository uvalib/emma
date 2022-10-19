# app/records/bs/record/bookmark.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Bookmark
#
# @attr [String]                           bookshareId
# @attr [IsoDate]                          dateAdded
# @attr [Bs::Record::Format]               format
# @attr [Array<Bs::Record::Link>]          links
# @attr [String]                           location
# @attr [Integer]                          position
# @attr [Float]                            progression
# @attr [String]                           text
# @attr [Float]                            totalProgression
#
# @see https://apidocs.bookshare.org/reference/index.html#_bookmark
#
class Bs::Record::Bookmark < Bs::Api::Record

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :bookshareId
    has_one   :dateAdded,         IsoDate
    has_one   :format,            Bs::Record::Format
    has_many  :links,             Bs::Record::Link
    has_one   :location
    has_one   :position,          Integer
    has_one   :progression,       Float
    has_one   :text
    has_one   :totalProgression,  Float
  end

end

__loading_end(__FILE__)
