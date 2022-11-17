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
  # @type [Hash{Symbol=>String}]
  #
  # TODO: Might not be needed.
  #
  FILE_DATA_KEYS = {
    url:      'Remote File',
    name:     'Local File',
    data:     'Literal File Data',
    uploader: 'Uploader Data',
  }.freeze

  # ===========================================================================
  # :section: Record::FileData overrides
  # ===========================================================================

  public

  # Generate a record to express structured file data.
  #
  # @param [Hash, String, nil] data
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
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
