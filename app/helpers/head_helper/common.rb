# app/helpers/head_helper/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper methods supporting document '<head>' entries.
#
module HeadHelper::Common

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for '<head>' properties.
  #
  # @type [Hash{Symbol=>Any}]
  #
  #--
  # noinspection RailsI18nInspection, RubyMismatchedConstantType
  #++
  HEAD_CONFIG = I18n.t('emma.head', default: {}).deep_freeze

end

__loading_end(__FILE__)
