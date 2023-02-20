# app/models/manifest_item/field_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::FieldMethods

  include ManifestItem::Config

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  bit = -1

  identity  = 1 << (bit += 1)
  grid_rows = 1 << (bit += 1)
  transient = 1 << (bit += 1)
  timestamp = 1 << (bit += 1)
  file_data = 1 << (bit += 1)
  synthetic = 1 << (bit += 1)
  server    = 1 << (bit += 1)
  client    = 1 << (bit +  1)

  # Fields which are not directly related to :emma_data values.
  #
  # (These are the "en.manifest_item.record" fields with 'origin' == :system
  # plus the :file_data field.)
  #
  # @type [Array<Symbol>]
  #
  RECORD_COLUMNS = {
    id:             server | identity,
    manifest_id:    server | identity,
    row:                     grid_rows,
    delta:                   grid_rows,
    editing:        client | transient,
    deleting:       client | transient,
    last_saved:              timestamp,
    last_lookup:    client | timestamp,
    last_submit:    client | timestamp,
    created_at:     server | timestamp,
    updated_at:     server,
    file_data:               file_data,
    file_status:    server | synthetic,
    data_status:    server | synthetic,
    ready_status:   server | synthetic,
    repository:              nil,
    backup:         server | transient,
    last_indexed:   server | timestamp,
    submission_id:  server | identity,
  }.tap { |table|

    keys_for = ->(b) { table.select { |_, v| (v & b) == b }.keys.freeze }
    combine  = ->(*keys) { keys.flatten.uniq.freeze }

    ID_COLS         = keys_for.(identity)
    GRID_COLS       = keys_for.(grid_rows)
    DATE_COLS       = keys_for.(timestamp)
    TRANSIENT_COLS  = keys_for.(transient)
    CLIENT_COLS     = keys_for.(client)
    NON_DATA_COLS   = combine.(CLIENT_COLS, TRANSIENT_COLS)
    NON_EDIT_COLS   = combine.(ID_COLS, DATE_COLS, TRANSIENT_COLS)
    NON_BACKUP_COLS = combine.(GRID_COLS, ID_COLS, DATE_COLS, TRANSIENT_COLS)

  }.keys.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create :backup field contents.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self
  # @param [Hash]                    added  Added key/value pairs.
  #
  # @return [Hash]
  #
  def get_backup(item = nil, **added)
    item ||= default_to_self
    (item.try(:fields) || item || {}).except(*NON_BACKUP_COLS).merge!(added)
  end

  # Update backup field value.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self
  # @param [Hash]                    added  Added key/value pairs.
  #
  # @return [ManifestItem, Hash]
  #
  def set_backup!(item = nil, **added)
    item ||= default_to_self
    item[:backup] = get_backup(item, **added)
    # noinspection RubyMismatchedReturnType
    item
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
