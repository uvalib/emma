# app/models/record/sortable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods for applying a sort order to sets of records.
#
module Record::Sortable

  extend ActiveSupport::Concern

  include SqlMethods

  include Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sort order applied by default in #get_relation.
  #
  # @return [Symbol, String, Hash]
  #
  def default_sort
    implicit_order_column || pagination_column
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate an object to specify sorting.
  #
  # @param [any, nil] value
  # @param [Hash]     opt             To SortOrder#initialize.
  #
  # @return [SortOrder, nil]
  #
  def normalize_sort_order(value, **opt)
    value = default_sort if value.nil? || value.is_a?(TrueClass)
    SortOrder.new(value, record: true, **opt).presence
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generates SQL terms which mirror ManifestItem scopes.
  #
  # @param [String, Symbol] col
  # @param [Symbol]         tbl
  #
  # @return [String]
  #
  def sort_scope(col, tbl)
    raise unless tbl == :manifest_items
    case col.to_sym
      when :to_delete_item_count    then scope_to_delete(tbl)
      when :never_saved_item_count  then scope_never_saved(tbl)
      when :unsaved_item_count      then scope_unsaved(tbl)
      when :completed_item_count    then scope_completed(tbl)
      when :incomplete_item_count   then scope_incomplete(tbl)
      when :pending_item_count      then scope_pending(tbl)
      when :saved_item_count        then scope_saved(tbl)
    end
  end

  def scope_active(t)       = "#{t}.deleting is NOT TRUE"
  def scope_to_delete(t)    = "#{t}.deleting is TRUE"
  def scope_never_saved(t)  = "#{t}.last_saved IS NULL"
  def scope_unsaved(t)      = "#{t}.last_saved < #{t}.updated_at"
  def scope_completed(t)    = "#{t}.last_saved >= #{t}.updated_at"
  def scope_incomplete(t)   = sql_or(scope_never_saved(t), scope_unsaved(t))
  def scope_pending(t)      = sql_and(scope_active(t), scope_incomplete(t))
  def scope_saved(t)        = sql_and(scope_active(t), scope_completed(t))

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
