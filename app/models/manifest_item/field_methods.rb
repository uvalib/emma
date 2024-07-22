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
  client    = 1 << (bit += 1)
  no_show   = 1 << (bit +  1)

  # Fields which are not directly related to :emma_data values.
  #
  # (These are the "en.emma.record.manifest_item" fields with
  # 'origin' == :system plus the :file_data field.)
  #
  # @type [Array<Symbol>]
  #
  RECORD_COLUMNS = {
    id:             server | identity   | no_show,
    manifest_id:    server | identity   | no_show,
    row:                     grid_rows  | no_show,
    delta:                   grid_rows  | no_show,
    editing:        client | transient  | no_show,
    deleting:       client | transient  | no_show,
    last_saved:              timestamp,
    last_lookup:    client | timestamp  | no_show,
    last_submit:    client | timestamp,
    created_at:     server | timestamp  | no_show,
    updated_at:     server,
    data_status:    server | synthetic,
    file_status:    server | synthetic,
    ready_status:   server | synthetic,
    file_data:               file_data,
    repository:              nil,
    backup:         server | transient  | no_show,
    last_indexed:   server | timestamp  | no_show,
    submission_id:  server | identity   | no_show,
    field_error:    server | transient  | no_show,
  }.tap { |table|

    keys_for = ->(b) { table.select { |_, v| (v & b) == b }.keys.freeze }
    combine  = ->(*keys) { keys.flatten.uniq.freeze }

    CLIENT_COLS     = keys_for.(client)
    DATE_COLS       = keys_for.(timestamp)
    GRID_COLS       = keys_for.(grid_rows)
    ID_COLS         = keys_for.(identity)
    NO_SHOW_COLS    = keys_for.(no_show)
    STATUS_COLS     = keys_for.(synthetic)
    TRANSIENT_COLS  = keys_for.(transient)

    NON_DATA_COLS   = combine.(CLIENT_COLS, TRANSIENT_COLS)
    NON_EDIT_COLS   = combine.(ID_COLS, DATE_COLS, TRANSIENT_COLS)
    NON_BACKUP_COLS = combine.(GRID_COLS, ID_COLS, DATE_COLS, TRANSIENT_COLS)

  }.keys.freeze

  if sanity_check?
    sc = STATUS_COLS
    sr = STATUS_READY.keys
    sv = STATUS_VALID.keys
    diff = (sc - sr).presence and raise "STATUS_READY missing #{diff}"
    diff = (sr - sc).presence and raise "STATUS_READY - STATUS_COLS = #{diff}"
    diff = (sc - sv).presence and raise "STATUS_VALID missing #{diff}"
    diff = (sv - sc).presence and raise "STATUS_VALID - STATUS_COLS = #{diff}"
  end

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
