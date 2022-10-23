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

  # @private
  UPDATE_STATUS_OPTS = %i[file data ready overwrite].freeze

  # Update status field values.
  #
  # @param [ManifestItem,Hash,nil] item   Default: self
  # @param [Boolean]       file
  # @param [Boolean]       data
  # @param [Boolean]       ready
  # @param [Boolean]       overwrite  If *false* only add status values.
  # @param [Hash]          added      Fields that will be added to the item
  #
  # @return [ManifestItem, Hash]
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def update_status!(
    item = nil,
    file:       true,
    data:       true,
    ready:      true,
    overwrite:  true,
    **added
  )
    item ||= default_to_self
    file  &&= !item[:file_status]  unless overwrite
    data  &&= !item[:data_status]  unless overwrite
    ready &&= !item[:ready_status] unless overwrite
    item[:file_status]  = evaluate_file_status(item, **added)  if file
    item[:data_status]  = evaluate_data_status(item, **added)  if data
    item[:ready_status] = evaluate_ready_status(item, **added) if ready
    item
  end

  # Evaluate the readiness of ManifestItem for being included in a submission.
  #
  # @param [ManifestItem,Hash,nil] item   Source of field values (def: self).
  # @param [Boolean]               symbol
  # @param [Hash]                  added  Additional field values to use.
  #
  # @return [ReadyStatus]                 If *symbol* is *false*.
  # @return [Symbol]
  #
  def evaluate_ready_status(item = nil, symbol: true, **added)
    if (stat = added[:ready_status]&.to_sym).blank?
      item ||= default_to_self
      # noinspection RubyNilAnalysis
      data = item.is_a?(ManifestItem) ? item.fields : item.symbolize_keys
      data = data.merge!(added)
      stat = ready?(data) ? :ready : :missing
    end
    symbol ? stat : ReadyStatus(stat)
  end

  # Evaluate the readiness of the file upload associated with a ManifestItem.
  #
  # @param [ManifestItem,Hash,nil] item   Source of field values (def: self).
  # @param [Boolean]               symbol
  # @param [Hash]                  added  Additional field values to use.
  #
  # @return [FileStatus]                  If *symbol* is *false*.
  # @return [Symbol]
  #
  def evaluate_file_status(item = nil, symbol: true, **added)
    if (stat = added[:file_status]&.to_sym).blank?
      item ||= default_to_self
      # noinspection RubyNilAnalysis
      data = item.is_a?(ManifestItem) ? item.fields : item.symbolize_keys
      data = data.merge!(added)[:file_data]
      stat = (:missing if data.nil?) || (:invalid if data.blank?) || :complete
    end
    symbol ? stat : FileStatus(stat)
  end

  # Evaluate the readiness of ManifestItem metadata.
  #
  # @param [ManifestItem,Hash,nil] item   Source of field values (def: self).
  # @param [Boolean]               symbol
  # @param [Hash]                  added  Additional field values to use.
  #
  # @return [DataStatus]                  If *symbol* is *false*.
  # @return [Symbol]
  #
  def evaluate_data_status(item = nil, symbol: true, **added)

    status = ->(v) { symbol ? v : DataStatus(v) }
    value  = added[:data_status]&.to_sym&.presence and return status.(value)

    item ||= default_to_self
    # noinspection RubyNilAnalysis
    data   = item.is_a?(ManifestItem) ? item.fields : item.symbolize_keys
    data.merge!(added).delete_if { |_, v| v.blank? unless v.is_a?(FalseClass) }

    fields       = ManifestItem.database_fields
    rem_fields   = fields.select { |_, v| v[:category]&.start_with?('rem') }
    bib_fields   = fields.select { |_, v| v[:category]&.start_with?('bib') }

    rem_data     = data.slice(*rem_fields.keys).keys.presence
    bib_data     = data.slice(*bib_fields.keys).keys.presence

    return status.(:missing)  unless rem_data && bib_data
    return status.(:no_rem)   unless rem_data
    return status.(:no_bib)   unless bib_data

    rem_required = rem_fields.select { |_, v| v[:required] }.keys
    bib_required = bib_fields.select { |_, v| v[:required] }.keys

    adequate_rem = rem_required.difference(rem_data).blank?
    adequate_bib = bib_required.difference(bib_data).blank?
    extra_rem    = rem_data.difference(rem_required).present?
    extra_bib    = bib_data.difference(bib_required).present?
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

  public

  # Evaluate field values for readiness.
  #
  # @param [ManifestItem,Hash,nil] item   Source of field values (def: self).
  #
  # @return [Boolean]
  #
  def ready?(item = nil)
    item ||= default_to_self
    %i[file_status data_status].all? { |col| status_ok?(item, column: col) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether the given status is OK.
  #
  # @param [*]      item     Field values, or a value to check (default: self).
  # @param [Symbol] column   Field name.
  #
  def status_ok?(item = nil, column:)
    item ||= default_to_self
    item   = item[column] if item.is_a?(ManifestItem) || item.is_a?(Hash)
    STATUS_VALID[column].include?(item&.to_sym)
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
