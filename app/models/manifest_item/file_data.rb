# app/models/manifest_item/file_data.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::FileData

  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Record::FileData
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Top-level :file_data Hash keys for each data variant that can appear in the
  # :file_data record column.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  FILE_DATA_TYPES = {
    url:      { type: :reference, description: 'Remote File' },
    name:     { type: :reference, description: 'Local File' },
    data:     { type: :storage,   description: 'Immediate Data File' },
    uploader: { type: :storage,   description: 'Uploader Data' },
  }.freeze

  FILE_DATA_REFERENCE =
    FILE_DATA_TYPES.select { |_, v| v[:type] == :reference }.keys.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Name of the file referenced by :file_data if it does not contain Shrine
  # uploader metadata.
  #
  # @return [String]
  # @return [nil]
  #
  def file_reference
    file_data&.presence&.symbolize_keys&.values_at(:name, :url)&.compact&.first
  end

  # Return the reported size of the file, either as determined by the uploader
  # or initialized by the client-side prior to bulk submission.
  #
  # @return [Integer, nil]
  #
  def file_size
    fd = file_data&.presence&.symbolize_keys
    fd.dig(:metadata, :size) || fd[:size] if fd
  end

  # ===========================================================================
  # :section: Record::FileData overrides
  # ===========================================================================

  public

  # Generate a record to express structured file data.
  #
  # @param [Hash, String, nil] data
  # @param [Hash]              opt    Passed to #json_parse
  #
  # @return [Hash{String=>Any}]
  #
  # @note Only used by #file_attacher_load
  #
  # @see config/locales/bulk.en.yml "en.emma.bulk.grid.file"
  #
  def make_file_record(data, **opt)
    __debug "=== make_file_record ManifestItem === | data = #{data.inspect} | opt = #{opt.inspect}"
    result = json_parse(data, **opt) || {}
    result = result[:uploader] || result
    result[:storage] ? result.deep_stringify_keys : {}
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
