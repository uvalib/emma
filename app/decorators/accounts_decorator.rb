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
  # :section: BaseCollectionDecorator overrides
  # ===========================================================================

  public

  # By default, account listings are not :pageable -- that is, all items
  # matching the search criteria are expected to be rendered in a table which
  # is client-side sortable.
  #
  # @param [ActiveRecord::Relation, Paginator, Array, nil] obj
  # @param [Hash]                                          opt
  #
  def initialize(obj = nil, **opt)
    opt[:pageable] = false unless opt.key?(:pageable)
    super
  end

  # ===========================================================================
  # :section: BaseCollectionDecorator::Form overrides
  # ===========================================================================

  protected

  # The record IDs extracted from `*items*`.
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
