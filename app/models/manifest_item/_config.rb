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

  # Indicates whether cells in the 'file_data' column include the ability to
  # upload a file associated with the manifest item.
  #
  # @type [Boolean]
  #
  # @see file:assets/javascripts/controllers/manifest-edit.js *EMBED_UPLOADER*
  #
  EMBED_UPLOADER = false

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
  TYPE_CONFIGURATION = EnumType::CONFIGURATION[:manifest_item]

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

  if sanity_check?
    arg  = [STATUS_READY.keys, STATUS_VALID.keys]
    opt  = { n1: :STATUS_READY, n2: :STATUS_VALID }
    diff = cfg_diff(*arg, **opt).presence and raise(diff)
  end

  # ManifestItem record columns containing summary status information.
  #
  # @type [Array<Symbol>]
  #
  STATUS_COLUMNS = STATUS_VALID.keys.freeze

  # Status values and labels for the metadata associated with the item.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>String}}]
  #
  STATUS = TYPE_CONFIGURATION.slice(*STATUS_COLUMNS).freeze

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
# @see "en.emma.type.manifest_item.file_status"
#
class FileStatus < EnumType

  define_enumeration(ManifestItem::Config::STATUS[:file_status])

end

# Status values for the metadata associated with the item.
#
# @see "en.emma.type.manifest_item.data_status"
#
class DataStatus < EnumType

  define_enumeration(ManifestItem::Config::STATUS[:data_status])

end

# Status values for the submission status of the item.
#
# @see "en.emma.type.manifest_item.ready_status"
#
class ReadyStatus < EnumType

  define_enumeration(ManifestItem::Config::STATUS[:ready_status])

end

__loading_end(__FILE__)
