# app/models/upload/bulk_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Upload record methods to support bulk operations.
#
module Upload::BulkMethods

  include Upload::WorkflowMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fallback URL base. TODO: ?
  #
  # @type [String]
  #
  BULK_BASE_URL = PRODUCTION_URL

  # Default user for bulk uploads. # TODO: ?
  #
  # @type [String]
  #
  BULK_USER = 'emmadso@bookshare.org'

  # Fields that used within the instance but are not persisted to the database.
  #
  # @type [Array<Symbol>]
  #
  LOCAL_FIELDS = %i[file_path].freeze

  # Fields that are expected to be included in :emma_data.
  #
  # @type [Array<Symbol>]
  #
  INDEX_FIELDS = Search::Record::MetadataRecord.field_names.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Bulk upload URL.
  #
  # @return [String, nil]
  #
  attr_reader :file_path

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Use the importer module to translate imported fields into Upload columns
  # and/or EMMA metadata fields.
  #
  # @param [Hash]           fields
  # @param [Module, String] importer_name
  #
  # @return [Hash]
  #
  def import_transform(fields, importer_name)
    importer = Import.get_importer(importer_name)
    Log.error { "#{__method__}: #{importer_name}: invalid" } if importer.blank?
    return fields if fields.blank? || importer.blank?

    known_names = field_names + INDEX_FIELDS + LOCAL_FIELDS
    known_fields, added_fields = partition_hash(fields, *known_names)
      .tap { |k, a| __debug_items { { known_fields: k, added_fields: a } } } # TODO: remove - debugging
    importer.translate_fields(added_fields).merge!(known_fields)
      .tap { |f| __debug_items { { fields: f } } } # TODO: remove - debugging
  end

end

__loading_end(__FILE__)
