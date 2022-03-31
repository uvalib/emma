# app/decorators/categories_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/category" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Bs::Record::CategorySummary>]
#
class CategoriesDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of CategoryDecorator

end

__loading_end(__FILE__)
