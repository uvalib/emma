# app/models/api/periodical_edition_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/edition_methods'

# Api::PeriodicalEditionSummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_periodical_edition_summary
#
class Api::PeriodicalEditionSummary < Api::Record::Base

  schema do
    attribute :editionId,   String
    attribute :editionName, String
  end

  include Api::Common::EditionMethods

end

__loading_end(__FILE__)
