# app/records/lookup/google_books/record/volume_info.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# General volume information.
#
# @attr [String]            title
# @attr [String]            subtitle
# @attr [Array<String>]     authors
# @attr [String]            publisher
# @attr [String]            publishedDate
# @attr [String]            description
# @attr [Array<Identifier>] industryIdentifiers
# @attr [Integer]           page_count
# @attr [Dimensions]        dimensions
# @attr [String]            printType ('BOOK' or 'MAGAZINE')
# @attr [Array<String>]     categories
# @attr [Float]             averageRating (1.0..5.0)
# @attr [Integer]           ratingsCount
# @attr [String]            contentVersion
# @attr [ImageLinks]        imageLinks
# @attr [String]            language
# @attr [String]            mainCategory
# @attr [String]            previewLink
# @attr [String]            infoLink
# @attr [String]            canonicalVolumeLink
#
# === Observed but not documented
#
# @attr [Integer]           printedPageCount
# @attr [String]            maturityRating      %w[... NOT_MATURE]
# @attr [Boolean]           allowAnonLogging
# @attr [Panelization]      panelizationSummary
# @attr [ReadingModes]      readingModes
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
#--
# noinspection LongLine
#++
class Lookup::GoogleBooks::Record::VolumeInfo < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CreatorMethods
  include Lookup::GoogleBooks::Shared::DateMethods
  include Lookup::GoogleBooks::Shared::IdentifierMethods
  include Lookup::GoogleBooks::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one  :title
    has_one  :subtitle
    has_many :authors
    has_one  :publisher
    has_one  :publishedDate
    has_one  :description
    has_many :industryIdentifiers,  Lookup::GoogleBooks::Record::Identifier
    has_one  :pageCount,            Integer
    has_one  :dimensions,           Lookup::GoogleBooks::Record::Dimensions
    has_one  :printType
    has_many :categories
    has_one  :averageRating,        Float
    has_one  :ratingsCount,         Integer
    has_one  :contentVersion
    has_one  :imageLinks,           Lookup::GoogleBooks::Record::ImageLinks
    has_one  :language
    has_one  :mainCategory
    has_one  :previewLink
    has_one  :infoLink
    has_one  :canonicalVolumeLink

    # === Observed but not documented:

    has_one  :printedPageCount,     Integer
    has_one  :maturityRating
    has_one  :allowAnonLogging,     Boolean
    has_one  :panelizationSummary,  Lookup::GoogleBooks::Record::Panelization
    has_one  :readingModes,         Lookup::GoogleBooks::Record::ReadingModes
  end

end

__loading_end(__FILE__)
