# app/records/bs/api/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared values and methods.
#
# @see Api::Common
#
module Bs::Api::Common

  include Api::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Type configurations.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/types/bookshare.en.yml *en.emma.bookshare.type*
  #
  CONFIGURATION = I18n.t('emma.bookshare.type').deep_freeze

  # Enumeration scalar type names and properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see #CONFIGURATION
  #
  ENUMERATIONS =
    CONFIGURATION
      .transform_values { |cfg| cfg.except(:_default).keys.map(&:to_s) }
      .deep_freeze

  # Enumeration type names.
  #
  # @type [Array<Symbol>]
  #
  # @see #CONFIGURATION
  #
  ENUMERATION_TYPES = CONFIGURATION.keys.freeze

  # Enumeration default values.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see #CONFIGURATION
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
#
# Values for each class come from the equivalently-name key in
# Bs::Api::Common::CONFIGURATION.
# =============================================================================

class BsAccess                  < EnumType; end
class BsListAccess              < EnumType; end
class BsAgreementType           < EnumType; end
class BsAllowsType              < EnumType; end
class BsBrailleFmt              < EnumType; end
class BsBrailleGrade            < EnumType; end
class BsBrailleMusicScoreLayout < EnumType; end
class BsBrailleType             < EnumType; end
class BsCategoryType            < EnumType; end
class BsContentWarning          < EnumType; end
class BsContributorType         < EnumType; end
class BsSortDirection           < EnumType; end
class BsSortDirectionRev        < EnumType; end
class BsDisabilityPlan          < EnumType; end
class BsDisabilityType          < EnumType; end
class BsExternalFormatType      < EnumType; end
class BsFormatType              < EnumType; end
class BsPeriodicalFormat        < EnumType; end
class BsGender                  < EnumType; end
class BsLexileCode              < EnumType; end
class BsMessagePriority         < EnumType; end
class BsMessageType             < EnumType; end
class BsMetricType              < EnumType; end
class BsMusicScoreType          < EnumType; end
class BsNarratorType            < EnumType; end
class BsProofOfDisabilitySource < EnumType; end
class BsProofOfDisabilityStatus < EnumType; end
class BsRightsType              < EnumType; end
class BsRoleType                < EnumType; end
class BsSeriesType              < EnumType; end
class BsScanQuality             < EnumType; end
class BsSiteType                < EnumType; end
class BsSubscriptionStatus      < EnumType; end
class BsTimeframe               < EnumType; end
class BsTitleContentType        < EnumType; end
class BsTitleSortOrder          < EnumType; end
class BsTitleStatus             < EnumType; end
class BsHistorySortOrder        < EnumType; end
class BsMemberSortOrder         < EnumType; end
class BsMyAssignedSortOrder     < EnumType; end
class BsAssignedSortOrder       < EnumType; end
class BsActiveBookSortOrder     < EnumType; end
class BsPeriodicalSortOrder     < EnumType; end
class BsEditionSortOrder        < EnumType; end
class BsMyReadingListSortOrder  < EnumType; end
class BsReadingListSortOrder    < EnumType; end
class BsCatalogSortOrder        < EnumType; end
class BsMessageSortOrder        < EnumType; end
class BsBrailleCode             < EnumType; end
class BsBrailleGrade2           < EnumType; end
class BsAuthType                < EnumType; end
class BsGrantType               < EnumType; end
class BsTokenErrorType          < EnumType; end

__loading_end(__FILE__)
