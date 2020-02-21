# app/records/bs/api/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/common'

# Shared values and methods.
#
# @see Api::Common
#
module Bs::Api::Common

  include ::Api::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Enumeration scalar type names and properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  ENUMERATIONS = {

    Access: {
      values:   %w(private shared org),
      default:  'shared'
    },

    AgreementType: {
      values:   %w(individual volunteer sponsor),
      default:  'individual'
    },

    # NOTE: Compare with ApiService#HTTP_METHODS.
    AllowsType: {
      values:   %w(PUT POST DELETE)
    },

    BrailleFmt: {
      values:   %w(refreshable embossable),
      default:  'embossable'
    },

    BrailleGrade: {
      values:   %w(contracted uncontracted),
      default:  'uncontracted'
    },

    BrailleMusicScoreLayout: {
      values:   %w(barOverBar barByBar),
      default:  'barOverBar'
    },

    BrailleType: {
      values:   %w(automated transcribed),
      default:  'automated'
    },

    CategoryType: {
      values:   %w(Bookshare BISAC),
      default:  'Bookshare'
    },

    # @see https://apidocs.bookshare.org/reference/index.html#_content_warning_values
    ContentWarning: {
      values:   %w(contentWarning sex violence drugs language intolerance) +
                  %w(adult unrated),
      default:  'unrated'
    },

    ContributorType: {
      values:   %w(author coWriter epilogueBy forwardBy introductionBy) +
                  %w(editor composer arranger lyricist translator) +
                  %w(transcriber abridger adapter),
    },

    Direction: {
      values:   %w(asc desc),
      default:  'asc'
    },

    Direction2: {
      values:   %w(asc desc),
      default:  'desc'
    },

    DisabilityPlan: {
      values:   %w(iep section504),
    },

    DisabilityType: {
      values:   %w(visual learning physical nonspecific),
      default:  'nonspecific'
    },

    # NOTE: The API does not mention 'HTML' or 'TEXT' but they exist.
    FormatType: {
      values:   %w(DAISY DAISY_SEGMENTED DAISY_AUDIO BRF EPUB3 PDF DOCX) +
                  %w(HTML TEXT),
      default:  'DAISY'
    },

    PeriodicalFormatType: {
      values:   %w(DAISY DAISY_2_AUDIO DAISY_AUDIO BRF)
    },

    Gender: {
      values:   %w(male female otherNonBinary),
      default:  'Other'
    },

    NarratorType: {
      values:   %w(tts human),
      default: 'human'
    },

    ProofOfDisabilitySource: {
      values:   %w(schoolVerified faxed nls learningAlly partner hadley),
      default:  'schoolVerified'
    },

    ProofOfDisabilityStatus: {
      values:   %w(active missing),
      default:  'active'
    },

    # NOTE: Compare with Roles#BOOKSHARE_ROLES.
    RoleType: {
      values: %w(individual volunteer trustedVolunteer collectionAssistant
                membershipAssistant)
    },

    SeriesType: {
      values: %w(newspaper magazine journal)
    },

    # NOTE: The value 'emma' may not be honored by Bookshare yet.
    SiteType: {
      values:   %w(bookshare cela rnib emma),
      default:  'bookshare'
    },

    SubscriptionStatus: {
      values:   %w(active expired missing),
      default:  'active'
    },

    Timeframe: {
      values:   %w(monthly entireSubscription),
      default:  'monthly'
    },

    TitleContentType: {
      values:   %w(text musicScore),
      default:  'text'
    },

    TitleSortOrder: {
      values:   %w(relevance title author dateAdded copyrightDate),
      default:  'title'
    },

    # === Account ===

    HistorySortOrder: {
      values:   %w(title author dateDownloaded),
      default:  'title'
    },

    # === Members ===

    MemberSortOrder: {
      values:   %w(dateAdded lastName firstName email userId district school
                  grade birthDate status),
      default:  'lastName'
    },

    # === Assigned Titles ===

    MyAssignedSortOrder: {
      values:   %w(title author),
      default:  'title'
    },

    AssignedSortOrder: {
      values:   %w(title author assignedBy assignedDate downloadDate),
      default:  'title'
    },

    # === Active Books / Active Periodicals ===

    ActiveBookSortOrder: {
      values:   %w(title dateAdded assigner),
      default:  'dateAdded'
    },

    # === Periodicals ===

    PeriodicalSortOrder: {
      values:   %w(title),
      default:  'title'
    },

    # === Periodical Editions ===

    EditionSortOrder: {
      values:   %w(editionName),
      default:  'editionName'
    },

    # === Reading Lists ===

    # NOTE: "count" (by title count) is undocumented.
    MyReadingListSortOrder: {
      values:   %w(name owner dateUpdated count),
      default:  'name'
    },

    ReadingListSortOrder: {
      values:   %w(title dateAddedToReadingList author),
      default:  'title'
    },

    # === Catalog ===

    CatalogSortOrder: {
      values:   %w(relevance title author updatedDate copyrightDate),
      default:  'title'
    },

    # === From catalog.bookshare.org (not in the API) ===

    ScanQuality: {
      values:   %w(EXCELLENT GOOD)
    },

    BrailleCode: {
      values:   %w(EBAE UEB FRENCH FRENCH_QUEBEC FRENCH_UNIFIED
                  STANDARD_ENGLISH_BRAILLE MUSIC_BRAILLE_CODE)
    },

    BrailleGrade2: {
      values:   %w(GRADE_2 GRADE_1) # contracted, uncontracted
    },

    # === Authorization ===

    AuthType: {
      values:   %w(code token)
    },

    GrantType: {
      values:   %w(authorization_code refresh_token password)
    },

    # NOTE: "unauthorized" is documented as "unauthorized_client".
    TokenErrorType: {
      values:   %w(invalid_request unauthorized access_denied
                  unsupported_response_type invalid_scope server_error
                  temporarily_unavailable)
    },
  }.deep_freeze.tap { |entries| ::EnumType.add_enumerations(entries) }

end

# =============================================================================
# Generate top-level classes associated with each enumeration entry so that
# they can be referenced without prepending a namespace.
# =============================================================================

class Access                  < EnumType; end
class AgreementType           < EnumType; end
class AllowsType              < EnumType; end
class BrailleFmt              < EnumType; end
class BrailleGrade            < EnumType; end
class BrailleMusicScoreLayout < EnumType; end
class BrailleType             < EnumType; end
class CategoryType            < EnumType; end
class ContentWarning          < EnumType; end
class ContributorType         < EnumType; end
class Direction               < EnumType; end
class Direction2              < EnumType; end
class DisabilityPlan          < EnumType; end
class DisabilityType          < EnumType; end
class FormatType              < EnumType; end
class PeriodicalFormatType    < EnumType; end
class Gender                  < EnumType; end
class NarratorType            < EnumType; end
class ProofOfDisabilitySource < EnumType; end
class ProofOfDisabilityStatus < EnumType; end
class RoleType                < EnumType; end
class SeriesType              < EnumType; end
class SiteType                < EnumType; end
class SubscriptionStatus      < EnumType; end
class Timeframe               < EnumType; end
class TitleContentType        < EnumType; end
class TitleSortOrder          < EnumType; end
class HistorySortOrder        < EnumType; end
class MemberSortOrder         < EnumType; end
class MyAssignedSortOrder     < EnumType; end
class AssignedSortOrder       < EnumType; end
class ActiveBookSortOrder     < EnumType; end
class PeriodicalSortOrder     < EnumType; end
class EditionSortOrder        < EnumType; end
class MyReadingListSortOrder  < EnumType; end
class ReadingListSortOrder    < EnumType; end
class CatalogSortOrder        < EnumType; end
class ScanQuality             < EnumType; end
class BrailleCode             < EnumType; end
class BrailleGrade2           < EnumType; end
class AuthType                < EnumType; end
class GrantType               < EnumType; end
class TokenErrorType          < EnumType; end

__loading_end(__FILE__)
