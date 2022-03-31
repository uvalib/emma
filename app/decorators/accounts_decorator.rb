# app/decorators/account_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/account" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<User>]
#
class AccountsDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of AccountDecorator

  # ===========================================================================
  # :section: BaseCollectionDecorator::Form overrides
  # ===========================================================================

  protected

  # item_ids
  #
  # @param [Array<User,String>, User, String, nil] items  Def: `#object`.
  #
  # @return [Array<String>]
  #
  def item_ids(items = nil, **)
    items ||= object
    User.compact_ids(*items)
  end

end

__loading_end(__FILE__)
