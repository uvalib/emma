# app/decorators/users_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/user" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<User>]
#
class UsersDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of UserDecorator

end

__loading_end(__FILE__)
