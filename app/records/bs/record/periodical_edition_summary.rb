# app/records/bs/record/periodical_edition_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::PeriodicalEditionSummary
#
# @attr [String] editionId
# @attr [String] editionName
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_edition_summary
#
class Bs::Record::PeriodicalEditionSummary < Bs::Api::Record

  include Bs::Shared::EditionMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :editionId
    has_one   :editionName
  end

end

__loading_end(__FILE__)
