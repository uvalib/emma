# app/models/manifest_item/status_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::StatusMethods

  include ManifestItem::Config
  include ManifestItem::Validatable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Update status field values.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  # @param [Boolean] file             If *false* preserve :file_status.
  # @param [Boolean] data             If *false* preserve :data_status.
  # @param [Boolean] ready            If *false* preserve :ready_status.
  # @param [Boolean] overwrite        If *false* only set null status values.
  # @param [Hash]    added            Fields that will be added to the item
  #
  # @return [ManifestItem, Hash]
  #
  def update_status!(
    item = nil,
    file:       true,
    data:       true,
    ready:      true,
    overwrite:  true,
    **added
  )
    item  ||= default_to_self
    file  &&= overwrite || item[:file_status].nil?
    data  &&= overwrite || item[:data_status].nil?
    ready &&= overwrite || item[:ready_status].nil?
    item[:file_status]  = evaluate_file_status(item, **added)  if file
    item[:data_status]  = evaluate_data_status(item, **added)  if data
    item[:ready_status] = evaluate_ready_status(item, **added) if ready
    # noinspection RubyMismatchedReturnType
    item
  end

  # @private
  UPDATE_STATUS_OPT = method_key_params(:update_status!).freeze

  # Evaluate the readiness of ManifestItem for being included in a submission.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  # @param [Boolean]                 symbol
  # @param [Hash]                    added  Additional field values to use.
  #
  # @return [ReadyStatus]                 If *symbol* is *false*.
  # @return [Symbol]
  #
  def evaluate_ready_status(item = nil, symbol: true, **added)
    if (value = added[:ready_status]).blank?
      data  = item_fields(item, added)
      value = ready?(data) ? :ready : :missing
    end
    symbol ? value.to_sym : ReadyStatus(value)
  end

  # Evaluate the readiness of the file upload associated with a ManifestItem.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  # @param [Boolean]                 symbol
  # @param [Hash]                    added  Additional field values to use.
  #
  # @return [FileStatus]                  If *symbol* is *false*.
  # @return [Symbol]
  #
  def evaluate_file_status(item = nil, symbol: true, **added)
    if (value = added[:file_status]).blank?
      data, err = item_fields(item, added).values_at(:file_data, :field_error)
      data  &&= ManifestItem.normalize_file(data)&.compact_blank!
      value   = (:missing   if data.blank?)
      value ||= (:invalid   if err&.dig(:file_data)&.present?)
      value ||= (:url_only  if data[:url])
      value ||= (:name_only if data[:name])
      value ||= (:complete  if data[:storage])
      value ||= :invalid
    end
    symbol ? value.to_sym : FileStatus(value)
  end

  # Evaluate the readiness of ManifestItem metadata.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  # @param [Boolean]                 symbol
  # @param [Hash]                    added  Additional field values to use.
  #
  # @return [DataStatus]                  If *symbol* is *false*.
  # @return [Symbol]
  #
  def evaluate_data_status(item = nil, symbol: true, **added)

    status = ->(stat) { symbol ? stat.to_sym : DataStatus(stat) }
    return status.(added[:data_status]) if added[:data_status].present?

    data   = item_fields(item, added).keep_if { |_, v| v || (v == false) }
    errors = data[:field_error]&.except(:file_data)
    return status.(:invalid) if errors.present?

    fields       = database_fields
    rem_fields   = fields.select { |_, v| v[:category]&.start_with?('rem') }
    bib_fields   = fields.select { |_, v| v[:category]&.start_with?('bib') }

    rem_data     = (data.keys & rem_fields.keys).presence
    bib_data     = (data.keys & bib_fields.keys).presence

    return status.(:missing)  unless rem_data || bib_data
    return status.(:no_rem)   unless rem_data
    return status.(:no_bib)   unless bib_data

    rem_required = rem_fields.select { |_, v| v[:required] }.keys
    bib_required = bib_fields.select { |_, v| v[:required] }.keys

    adequate_rem = (rem_required - rem_data).blank?
    adequate_bib = (bib_required - bib_data).blank?
    extra_rem    = (rem_data - rem_required).present?
    extra_bib    = (bib_data - bib_required).present?
    complete_rem = adequate_rem && extra_rem
    complete_bib = adequate_bib && extra_bib

    return status.(:complete) if complete_rem && complete_bib
    return status.(:min_bib)  if complete_rem && adequate_bib
    return status.(:min_rem)  if adequate_rem && adequate_bib

    status.(:invalid)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Return indicated field values.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  # @param [Hash, nil]               added  Additional field values to use.
  #
  # @return [Hash]
  #
  def item_fields(item, added = nil)
    item ||= default_to_self
    result = item.is_a?(ManifestItem) ? item.fields : item.symbolize_keys
    added ? result.merge!(added) : result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate the item represents unsaved data.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  def unsaved?(item = nil)
    item     ||= default_to_self
    last_saved = item[:last_saved]
    updated_at = item[:updated_at]
    last_saved.blank? || (updated_at.present? && (last_saved < updated_at))
  end

  # Evaluate field values for readiness.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  def ready?(item = nil)
    item ||= default_to_self
    %i[file_status data_status].all? { |col| status_ok?(item, column: col) }
  end

  # Indicate whether the item has been associated with a file.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  def file_ok?(item = nil)
    status_ok?(item, column: :file_status)
  end

  # Indicate whether the item has valid data.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  def data_ok?(item = nil)
    status_ok?(item, column: :data_status)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether the given status is OK.
  #
  # @param [any, nil] item      Field values, or a value to check (def.: self).
  # @param [Symbol]   column    Field name.
  #
  def status_ok?(item = nil, column:)
    item ||= default_to_self
    item   = item[column] if item.is_a?(ManifestItem) || item.is_a?(Hash)
    STATUS_VALID[column].include?(item&.to_sym)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the item's :file_data field references a local asset.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  # @example File at a local (client-side) location
  #   { "name" => "my_file.zip", ... }
  #
  def file_name?(item = nil)
    pending_file_name(item).present?
  end

  # Indicate whether the item's :file_data field references a remote asset.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  # @example File at a remote location
  #   { "url" => "https://host/path/file...", ... }
  #
  def file_url?(item = nil)
    pending_file_url(item).present?
  end

  # Indicate whether the item contains encoded file data in the :file_data
  # field.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  # @example Literal (encoded) file data
  #   { "data" => "STRING_OF_CHARACTERS", ... }
  #
  def file_literal?(item = nil)
    encoded_file_data(item).present?
  end

  # Indicate whether the item's :file_data field contains information from a
  # Shrine upload to AWS.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  # @example Uploaded file
  #   { "id" => "...", "storage" => "cache", ... }
  #
  # @example Alternate form (not currently used)
  #   { "uploader" => { "id" => "...", "storage" => "cache", ... } ... }
  #
  def file_uploaded?(item = nil)
    file_upload_data(item).present?
  end

  # Dynamically check the item's :file_data field by reloading.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  def file_uploaded_now?(item = nil)
    item ||= default_to_self
    item.reload if item.is_a?(ActiveRecord::Base)
    file_uploaded?(item)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return with the local filename that has been associated with the item.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  # @return [String, nil]
  #
  def pending_file_name(item = nil)
    get_file_data(item)[:name].presence
  end

  # Return with the remote filename that has been associated with the item.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  # @return [String, nil]
  #
  def pending_file_url(item = nil)
    get_file_data(item)[:url].presence
  end

  # Return with encoded file data that has been associated with the item.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  # @return [String, nil]
  #
  def encoded_file_data(item = nil)
    get_file_data(item)[:data].presence
  end

  # Return with uploader data that has been associated with the item.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  # @return [Hash, nil]
  #
  def file_upload_data(item = nil)
    fd = get_file_data(item)
    fd = fd[:uploader]     if fd[:uploader].is_a?(Hash)
    fd.deep_symbolize_keys if fd[:storage].present?
  end

  # Return the named file associated with the item along with a value
  # indicating its mode of access.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  # @return [Array(String,Symbol), nil]
  #
  def file_name_type(item = nil)
    fd   = get_file_data(item)
    file = file_upload_data(fd)
    file = file&.dig(:metadata, :filename)  and return [file, :uploader]
    file = pending_file_name(fd)            and return [file, :name]
    file = pending_file_url(fd)             and return [file, :url]
    ['ENCODED', :data] if encoded_file_data(fd) # TODO: don't handle this yet
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # get_file_data
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  # @return [Hash]
  #
  def get_file_data(item)
    item ||= default_to_self
    # noinspection RubyMismatchedReturnType
    item[:file_data]&.symbolize_keys || (item.is_a?(Hash) ? item : {})
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the item is now in the EMMA Unified Index.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  def in_index?(item = nil)
    item ||= default_to_self
    last_saved   = item[:last_saved]
    last_indexed = item[:last_indexed]
    last_indexed.present? && last_saved.present? && (last_indexed > last_saved)
  end

  # Indicate whether the item is now associated with an EMMA entry.
  #
  # @param [ManifestItem, Hash, nil] item   Default: self.
  #
  def submitted?(item = nil)
    item ||= default_to_self
    item[:submission_id].present? &&
      (last_submit  = item[:last_submit]).present? &&
      (last_indexed = item[:last_indexed]).present? &&
      (last_submit > last_indexed)
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
