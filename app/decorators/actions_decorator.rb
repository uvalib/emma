# app/decorators/actions_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/action" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Action>]
#
class ActionsDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of ActionDecorator

end

__loading_end(__FILE__)
