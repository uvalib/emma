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

    # TODO: ???

  end

  # ===========================================================================
  # :section: Types
  # ===========================================================================

  public

  # noinspection RubyConstantNamingConvention
  Boolean = TrueClass

  # Base class for custom scalar types.
  #
  class ScalarType

    attr_reader :value

    def initializer(v = nil)
      set(v)
    end

    def value=(v)
      set(v)
    end

    def default
      ''
    end

    def valid?(v = @value)
      v.present?
    end

    def set(v)
      # noinspection RubyAssignmentExpressionInConditionalInspection
      unless v.nil? || valid?(v = v.to_s.strip)
        Log.error("#{self.class}: #{v.inspect}")
        v = nil
      end
      @value = v || default
    end

    delegate_missing_to :value

  end

  # ISO 8601 duration.
  #
  class IsoDuration < ScalarType

    def valid?(v = @value)
      v = v.to_s
      v.match?(/^P(\d+Y)?(\d+M)?(\d+D)?(T(\d+H)?(\d+M)?(\d+(\.\d+)?S)?)?$/)
    end

  end

  # ISO 8601 general date.
  #
  class IsoDate < ScalarType

    def valid?(v = @value)
      v = v.to_s
      year?(v) || day?(v) || v.match?(/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dTZD$/)
    end

    def year?(v = @value)
      v.to_s.match?(/^\d{4}/)
    end

    def day?(v = @value)
      v.to_s.match?(/^\d{4}-\d\d-\d\d$/)
    end

  end

  # ISO 8601 day.
  #
  class IsoDay < IsoDate

    def valid?(v = @value)
      day?(v)
    end

  end

  # ===========================================================================
  # :section: Enumeration Types
  # ===========================================================================

  public

  # Enumeration scalar type names and properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # == Usage Notes
  # :AllowsType     Compare with ApiService#HTTP_METHODS.
  # :FormatType     The API does not mention 'HTML' or 'TEXT' but they exist.
  # :RoleType       Compare with Roles#BOOKSHARE_ROLES.
  # :SiteType       The value 'emma' may not be honored by Bookshare yet.
  # :TokenErrorType "unauthorized_client" appears as "unauthorized".
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

    AllowsType: {
      values:   %w(PUT POST DELETE)
    },

    BrailleFormat: {
      values:   %w(refreshable embossable),
      default:  'embossable'
    },

    BrailleGrade: {
      values:   %w(grade_1 grade_2),
      default:  'grade_1'
    },

    BrailleGrade2: {
      values:   %w(contracted uncontracted),
      default:  'uncontracted'
    },

    BrailleMusicScoreLayout: {
      values:   ['bar over bar', 'bar by bar'],
      default:  'bar over bar'
    },

    BrailleType: {
      values:   %w(automated transcribed),
      default:  'automated'
    },

    CategoryType: {
      values:   %w(Bookshare BISAC),
      default:  'Bookshare'
    },

    Direction: {
      values:   %w(asc desc),
      default:  'asc'
    },

    Direction2: {
      values:   %w(asc desc),
      default:  'desc'
    },

    DisabilityType: {
      values:   %w(visual learning physical nonspecific),
      default:  'nonspecific'
    },

    FormatType: {
      values:   %w(DAISY DAISY_SEGMENTED DAISY_AUDIO BRF EPUB3 PDF DOCX) +
                  %w(HTML TEXT),
      default:  'DAISY'
    },

    Gender: {
      values:   %w(Male Female Other),
      default:  'Other'
    },

    NarratorType: {
      values:   %w(TTS Human),
      default: 'Human'
    },

    ProofOfDisabilitySource: {
      values:   %w(schoolVerified faxed nls learningAlly partner hadley),
      default:  'schoolVerified'
    },

    ProofOfDisabilityStatus: {
      values:   %w(active missing),
      default:  'active'
    },

    RoleType: {
      values: %w(individual volunteer trustedVolunteer collectionAssistant
                membershipAssistant)
    },

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

    MyReadingListSortOrder: {
      values:   %w(name owner dateUpdated),
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

    # === Authorization ===

    AuthType: {
      values:   %w(code token)
    },

    GrantType: {
      values:   %w(authorization_code refresh_token password)
    },

    TokenErrorType: {
      values:   %w(invalid_request unauthorized access_denied
                  unsupported_response_type invalid_scope server_error
                  temporarily_unavailable)
    },
  }.deep_freeze

  # Base class for enumeration scalar types.
  #
  class EnumType < ScalarType

    def initialize(v = nil, *)
      set(v)
    end

    def default
      @default ||= ENUMERATIONS.dig(type, :default) || values.first
    end

    def valid?(v = @value)
      values.include?(v.to_s)
    end

    def set(v)
      # noinspection RubyAssignmentExpressionInConditionalInspection
      unless v.nil? || valid?(v = v.to_s.strip)
        Log.warn("#{type}: #{v.inspect}: not in #{values}")
        v = nil
      end
      @value = v || default
    end

    def type
      @type ||= self.class.to_s.demodulize.to_sym
    end

    def values
      @values ||= ENUMERATIONS.dig(type, :values)
    end

    def to_s
      @value.to_s
    end

    def inspect
      "(#{to_s.inspect})"
    end

  end

  ENUMERATIONS.each_key do |type|
    class_eval("class #{type} < EnumType; end")
  end

end unless defined?(Api) && defined?(Api::Common)

__loading_end(__FILE__)
