# app/models/manifest_item/file_data.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::FileData

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Record::FileData
  end
  # :nocov:

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
  # @return [Hash{String=>any,nil}]
  #
  # @note Only used by #file_attacher_load
  #
  # @see config/locales/bulk.en.yml "en.emma.bulk.grid.file"
  #
  def make_file_record(data, **opt)
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
