# app/records/bs/record/assigned_title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::AssignedTitleMetadataSummary
#
# @attr [String]                    assignedBy
# @attr [Array<Bs::Record::Name>]   authors            *deprecated*
# @attr [Boolean]                   available
# @attr [String]                    bookshareId
# @attr [Array<Bs::Record::Name>]   composers          *deprecated*
# @attr [IsoYear]                   copyrightDate
# @attr [String]                    dateAdded
# @attr [String]                    dateDownloaded
# @attr [Array<Bs::Record::Format>] formats
# @attr [String]                    instruments
# @attr [String]                    isbn13
# @attr [Array<String>]             languages
# @attr [Array<Bs::Record::Link>]   links
# @attr [IsoDate]                   publishDate
# @attr [String]                    seriesNumber
# @attr [String]                    seriesTitle
# @attr [String]                    subtitle
# @attr [String]                    synopsis
# @attr [String]                    title
# @attr [String]                    titleContentType
# @attr [String]                    vocalParts
#
# @see https://apidocs.bookshare.org/reference/index.html#_assigned_title_metadata_summary
#
# == Implementation Notes
# Similar to Bs::Record::TitleMetadataSummary, but without these fields:
#   :arrangers
#   :contentWarnings
#   :contributors
#   :lyricists
#   :translators
# And adds these fields:
#   :assignedBy
#   :dateAdded
#   :dateDownloaded
#
class Bs::Record::AssignedTitleMetadataSummary < Bs::Api::Record

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::CreatorMethods
  include Bs::Shared::IdentifierMethods
  include Bs::Shared::LinkMethods
  include Bs::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :assignedBy
    has_many  :authors,          Bs::Record::Name           # NOTE: deprecated
    has_one   :available,        Boolean
    has_one   :bookshareId
    has_many  :composers,        Bs::Record::Name           # NOTE: deprecated
    has_one   :copyrightDate,    IsoYear
    has_one   :dateAdded
    has_one   :dateDownloaded
    has_many  :formats,          Bs::Record::Format
    has_one   :instruments
    has_one   :isbn13
    has_many  :languages
    has_many  :links,            Bs::Record::Link
    has_one   :publishDate,      IsoDate
    has_one   :seriesNumber
    has_one   :seriesTitle
    has_one   :subtitle
    has_one   :synopsis
    has_one   :title
    has_one   :titleContentType
    has_one   :vocalParts
  end

end

__loading_end(__FILE__)
