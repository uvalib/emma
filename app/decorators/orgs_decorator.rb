# app/decorators/orgs_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/org" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Org>]
#
class OrgsDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of OrgDecorator

end

__loading_end(__FILE__)
