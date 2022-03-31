# app/decorators/phases_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/phase" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Phase>]
#
class PhasesDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of PhaseDecorator

end

__loading_end(__FILE__)
