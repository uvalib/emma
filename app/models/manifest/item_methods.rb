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

  # Return a table of all pending ManifestItem ID's and their status values.
  #
  # @param [Manifest, String, nil] manifest   Default: self
  # @param [Array<Symbol>]         columns    ManifestItem status columns.
  #
  # @return [Hash{Integer=>Hash}]
  #
  def pending_items_hash(manifest = nil, columns: STATUS_COLUMNS, **)
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
  def invalid_items_hash(manifest = nil, columns: STATUS_COLUMNS, **)
    items    = items_related_to(manifest) or return {}
    edited   = items.pending
    complete = columns.map { |c| [c, STATUS_VALID[c]] }.to_h.compact
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
      rows.pluck(:id, *cols).map { |id, *vals| [id, cols.zip(vals).to_h] }.to_h
    else
      rows.map { |row| [row.id, row.fields] }.to_h
    end
  end

  # The number of ManifestItems for the given Manifest (not including records
  # marked for deletion).
  #
  # @param [Manifest, String, *]        manifest  Default: self
  #
  # @return [Integer]
  #
  def item_count(manifest = nil, **)
    items_related_to(manifest)&.active&.size || 0
  end

  # The number of ManifestItems for the given Manifest that are valid.
  #
  # @param [Manifest, String, *]        manifest  Default: self
  #
  # @return [Integer]
  #
  def saved_item_count(manifest = nil, **)
    items_related_to(manifest)&.saved&.size || 0
  end

  # The number of ManifestItems for the given Manifest that have been created
  # or changed but not yet saved.
  #
  # @param [Manifest, String, *]        manifest  Default: self
  #
  # @return [Integer]
  #
  def pending_item_count(manifest = nil, **)
    items_related_to(manifest)&.pending&.size || 0
  end

  def updated_item_count(manifest = nil, **)
    items_related_to(manifest)&.updated&.size || 0
  end

  def unsaved_item_count(manifest = nil, **)
    items_related_to(manifest)&.unsaved&.size || 0
  end

  def never_saved_item_count(manifest = nil, **)
    items_related_to(manifest)&.never_saved&.size || 0
  end

  def incomplete_item_count(manifest = nil, **)
    items_related_to(manifest)&.incomplete&.size || 0
  end

  def to_delete_item_count(manifest = nil, **)
    items_related_to(manifest)&.to_delete&.size || 0
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
