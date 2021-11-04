# app/records/ingest/shared/date_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to dates.
#
module Ingest::Shared::DateMethods

  include Api::Shared::DateMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Schema elements which should be transmitted as "YYYY-MM-DD".
  #
  # @type [Array<Symbol>]
  #
  DAY_FIELDS = %i[
    dcterms_dateAccepted
    emma_lastRemediationDate
    emma_publicationDate
    emma_repositoryMetadataUpdateDate
    emma_repositoryUpdateDate
    emma_sortDate
    rem_remediationDate
  ].freeze

  # ===========================================================================
  # :section: Api::Shared::DateMethods overrides
  # ===========================================================================

  public

  # Field(s) that must be transmitted as "YYYY-MM-DD".
  #
  # @return [Array<Symbol>]
  #
  def day_fields
    DAY_FIELDS
  end

end

__loading_end(__FILE__)
