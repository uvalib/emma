# app/records/bs/record/highlight.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Highlight
#
# @attr [Array<BsAllowsType>]     allows
# @attr [String]                  annotationNote
# @attr [String]                  bookshareId
# @attr [String]                  color
# @attr [IsoDate]                 dateUpdated
# @attr [String]                  endLocation
# @attr [Integer]                 endPosition
# @attr [Float]                   endProgression
# @attr [Float]                   endTotalProgression
# @attr [Bs::Record::Format]      format
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  startLocation
# @attr [Integer]                 startPosition
# @attr [Float]                   startProgression
# @attr [Float]                   startTotalProgression
#
# @see https://apidocs.bookshare.org/reference/index.html#_highlight
#
class Bs::Record::Highlight < Bs::Api::Record

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many  :allows,                BsAllowsType
    has_one   :annotationNote
    has_one   :bookshareId
    has_one   :color
    has_one   :dateUpdated,           IsoDate
    has_one   :endLocation
    has_one   :endPosition,           Integer
    has_one   :endProgression,        Float
    has_one   :endTotalProgression,   Float
    has_one   :format,                Bs::Record::Format
    has_one   :highlightText
    has_many  :links,                 Bs::Record::Link
    has_one   :startLocation
    has_one   :startPosition,         Integer
    has_one   :startProgression,      Float
    has_one   :startTotalProgression, Float
  end

end

__loading_end(__FILE__)
