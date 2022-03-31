# app/decorators/reading_lists_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/reading_list" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Bs::Record::ReadingListUserView>]
#
class ReadingListsDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of ReadingListDecorator

end

__loading_end(__FILE__)
