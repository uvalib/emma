# app/models/manifest/item_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Manifest::ItemMethods

  include Manifest::Config

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default ManifestItem status columns for methods based on #items_hash.
  #
  # @type [Array<Symbol>]
  #
  PENDING_ITEM_COLS = [*ITEM_STATUS_COLUMNS, :last_saved, :updated_at].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return a table of all pending ManifestItem ID's and their status values.
  #
  # @param [Manifest, String, nil] manifest   Default: self
  # @param [Array<Symbol>]         columns    ManifestItem status columns.
  #
  # @return [Hash{Integer=>Hash}]
  #
  def pending_items_hash(manifest = nil, columns: PENDING_ITEM_COLS, **)
    items  = items_related_to(manifest) or return {}
    edited = items.pending
    items_hash(edited, columns: columns)
  end

  # Return a table of pending ManifestItem ID with incomplete status(es).
  #
  # @param [Manifest, String, nil] manifest   Default: self
  # @param [Array<Symbol>]         columns    ManifestItem status columns.
  #
  # @return [Hash{Integer=>Hash}]
  #
  # @note Not currently used.
  #
  def invalid_items_hash(manifest = nil, columns: PENDING_ITEM_COLS, **)
    items    = items_related_to(manifest) or return {}
    edited   = items.pending
    complete = columns.map { |c| [c, ITEM_STATUS_VALID[c]] }.to_h.compact
    invalid  = edited.where.not(**complete)
    items_hash(invalid, columns: columns)
  end

  # Return a table of ManifestItem values keyed on identifier.
  #
  # @param [Manifest, String, *]        manifest  Default: self
  # @param [Array<Symbol>, Symbol, nil] columns
  #
  # @return [Hash{Integer=>Hash}]
  #
  def items_hash(manifest = nil, columns: nil, **)
    rows = items_related_to(manifest) or return {}
    cols = Array.wrap(columns)
    if cols.present?
      # noinspection RailsParamDefResolve
      rows.pluck(:id, *cols).map { |id, *vals| [id, cols.zip(vals).to_h] }.to_h
    else
      rows.map { |row| [row.id, row.fields] }.to_h
    end
  end

  # The number of ManifestItems for the given Manifest (not including records
  # marked for deletion).
  #
  # @param [Manifest, String, *] manifest   Default: self
  #
  # @return [Integer]
  #
  # @see "en.emma.manifest.index.display_fields"
  #
  def item_count(manifest = nil, **)
    related_items_count(manifest, :active)
  end

  # The number of ManifestItems for the given Manifest that are valid.
  #
  # @param [Manifest, String, *] manifest   Default: self
  #
  # @return [Integer]
  #
  # @see "en.emma.manifest.index.display_fields"
  #
  def saved_item_count(manifest = nil, **)
    related_items_count(manifest, :saved)
  end

  # The number of ManifestItems for the given Manifest that have been created
  # or changed but not yet saved.
  #
  # @param [Manifest, String, *] manifest   Default: self
  #
  # @return [Integer]
  #
  # @see "en.emma.manifest.index.display_fields"
  #
  def pending_item_count(manifest = nil, **)
    related_items_count(manifest, :pending)
  end

  def completed_item_count(manifest = nil, **)
    related_items_count(manifest, :completed)
  end

  def unsaved_item_count(manifest = nil, **)
    related_items_count(manifest, :unsaved)
  end

  def never_saved_item_count(manifest = nil, **)
    related_items_count(manifest, :never_saved)
  end

  def incomplete_item_count(manifest = nil, **)
    related_items_count(manifest, :incomplete)
  end

  def to_delete_item_count(manifest = nil, **)
    related_items_count(manifest, :to_delete)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Items for the indicated Manifest.
  #
  # @param [Manifest, String, *] manifest   Default: self
  #
  # @return [ActiveRecord::Associations::Association<ManifestItem>, nil]
  #
  def items_related_to(manifest)
    manifest ||= default_to_self
    record     = manifest.is_a?(String) ? Manifest.find(manifest) : manifest
    # noinspection RubyMismatchedReturnType
    record.is_a?(Manifest) ? record.manifest_items : record
  end

  # The number of ManifestItems for the given Manifest that are included in the
  # given scope.
  #
  # @param [Manifest, String, *] manifest   Default: self
  # @param [Symbol]              scope
  #
  # @return [Integer]
  #
  def related_items_count(manifest, scope)
    items_related_to(manifest)&.send(scope)&.size || 0
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
