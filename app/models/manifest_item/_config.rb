# app/models/manifest_item/_config.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::Config

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # To avoid complications for the initial release of bulk submissions, there
  # is no selection of destination repository -- it is implicitly 'EMMA'.
  #
  # To support repository selection, set this value to *true*.
  #
  # @type [Boolean]
  #
  ALLOW_NIL_REPOSITORY = false

  # Status values and labels for the metadata associated with the item.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  MANIFEST_ITEM_TYPES = config_section('emma.manifest_item.type').deep_freeze

  # Values for each status column which indicate an unblocked status.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  STATUS_READY = {
    file_status:  %i[complete name_only],
    data_status:  %i[complete min_bib min_rem],
    ready_status: %i[ready],
  }.deep_freeze

  # Values for each status column which indicate an "OK" status.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  STATUS_VALID = {
    file_status:  %i[complete name_only url_only],
    data_status:  %i[complete min_bib min_rem],
    ready_status: %i[ready complete],
  }.deep_freeze

  # ManifestItem record columns containing summary status information.
  #
  # @type [Array<Symbol>]
  #
  STATUS_COLUMNS = STATUS_VALID.keys.freeze

  # Status values and labels for the metadata associated with the item.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>String}}]
  #
  STATUS = MANIFEST_ITEM_TYPES.slice(*STATUS_COLUMNS).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  EnumType.add_enumerations(MANIFEST_ITEM_TYPES)

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Used by methods defined in modules to allow the primary argument to be
  # missing/nil when used as a record instance method.
  #
  # @param [*, nil] item
  # @param [Symbol] from
  #
  # @return [*, ManifestItem]
  #
  def default_to_self(item = nil, from: nil)
    return item if item
    return self if self.is_a?(ManifestItem)
    meth = from || calling_method
    raise "#{meth} not being used as a record instance method"
  end

end

# =============================================================================
# Generate top-level classes associated with each enumeration entry so that
# they can be referenced without prepending a namespace.
# =============================================================================

# Status values for the remediated file associated with the item.
#
# @see "en.emma.manifest_item.type.file_status"
#
class FileStatus < EnumType; end

# Status values for the metadata associated with the item.
#
# @see "en.emma.manifest_item.type.data_status"
#
class DataStatus < EnumType; end

# Status values for the submission status of the item.
#
# @see "en.emma.manifest_item.type.ready_status"
#
class ReadyStatus < EnumType; end

__loading_end(__FILE__)
