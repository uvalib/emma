# app/decorators/periodicals_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/periodical" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Bs::Record::PeriodicalSeriesMetadataSummary>]
#
class PeriodicalsDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of PeriodicalDecorator

end

__loading_end(__FILE__)
