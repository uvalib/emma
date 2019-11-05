# app/models/concerns/api/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Api

  # Shared values and methods.
  #
  module Common

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # TODO: Api::Common methods ???

  end

  # ===========================================================================
  # :section: Enumeration Types
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

    BrailleFormat: {
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
                  %w(anyAdult unrated),
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
  }.deep_freeze

end

# noinspection RubyConstantNamingConvention
Boolean = Axiom::Types::Boolean

# Base class for custom scalar types.
#
class ScalarType

  attr_reader :value

  delegate_missing_to :value

  def initializer(v = nil, *)
    set(v)
  end

  def value=(v)
    set(v)
  end

  def set(v)
    v_normalized = normalize(v)
    acceptable   = v_normalized.nil? || valid?(v_normalized)
    Log.error("#{self.class}: #{v.inspect}") unless acceptable
    @value = acceptable && v_normalized || default
  end

  def valid?(v = nil)
    (v || @value).present?
  end

  def to_s
    @value.to_s
  end

  def inspect
    "(#{to_s.inspect})"
  end

  def default
    self.class.default
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  def normalize(v)
    v&.to_s&.strip
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  def self.default
    ''
  end

end

# ISO 8601 duration.
#
class IsoDuration < ScalarType

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def valid?(v = nil)
    v = v&.to_s&.strip || @value
    v.match?(/^P(\d+Y)?(\d+M)?(\d+D)?(T(\d+H)?(\d+M)?(\d+(\.\d+)?S)?)?$/)
  end

end

# ISO 8601 general date.
#
class IsoDate < ScalarType

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def valid?(v = nil)
    year?(v) || day?(v) ||
      (v&.to_s&.strip || @value).match?(/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dTZD$/)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def year?(v = nil)
    v = v&.to_s&.strip || @value
    v.match?(/^\d{4}$/)
  end

  def day?(v = nil)
    v = v&.to_s&.strip || @value
    v.match?(/^\d{4}-\d\d-\d\d$/)
  end

end

# ISO 8601 year.
#
class IsoYear < IsoDate

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def valid?(v = nil)
    year?(v)
  end

end

# ISO 8601 day.
#
class IsoDay < IsoDate

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def valid?(v = nil)
    day?(v)
  end

end

# ISO 639-2 alpha-3 language code.
#
class IsoLanguage < ScalarType

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def valid?(v = nil)
    v = normalize(v) || @value
    ISO_639.find_by_code(v).present?
  end

end

# Base class for enumeration scalar types.
#
class EnumType < ScalarType

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def set(v)
    # noinspection RubyAssignmentExpressionInConditionalInspection
    unless v.nil? || valid?(v = v.to_s.strip)
      Log.warn("#{type}: #{v.inspect}: not in #{values}")
      v = nil
    end
    @value = v || default
  end

  def valid?(v = @value)
    values.include?(v.to_s)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def type
    self.class.type
  end

  def values
    self.class.values
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  def self.type
    @type ||= self.to_s.to_sym
  end

  def self.values
    @values ||= Api::ENUMERATIONS.dig(type, :values)
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def self.default
    @default ||= Api::ENUMERATIONS.dig(type, :default) || values.first
  end

end

# Api::ENUMERATIONS.each_key { |et| class_eval("class #{et} < EnumType; end") }

class Access                  < EnumType; end
class AgreementType           < EnumType; end
class AllowsType              < EnumType; end
class BrailleFormat           < EnumType; end
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
