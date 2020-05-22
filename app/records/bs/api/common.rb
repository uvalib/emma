# app/records/bs/api/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

=begin
require 'api/common'
=end

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

  # Type configurations.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see config/locales/types/bookshare.en.yml
  #
  # noinspection RailsI18nInspection
  CONFIGURATION = I18n.t('emma.bookshare.type').deep_freeze

  # Enumeration scalar type names and properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see config/locales/types/bookshare.en.yml
  #
  # noinspection RailsI18nInspection
  ENUMERATIONS =
    CONFIGURATION
      .transform_values { |cfg| cfg.except(:_default).keys.map(&:to_s) }
      .deep_freeze

  # Enumeration type names.
  #
  # @type [Array<Symbol>]
  #
  # @see config/locales/types/bookshare.en.yml
  #
  ENUMERATION_TYPES = CONFIGURATION.keys.freeze

  # Enumeration default values.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see config/locales/types/bookshare.en.yml
  #
  ENUMERATION_DEFAULTS =
    CONFIGURATION.transform_values { |cfg| cfg[:_default] || '' }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  EnumType.add_enumerations(CONFIGURATION)

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
