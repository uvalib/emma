# app/models/phase/bulk_remove.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bulk entry removal workflow tracking record.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.phase.bulk_remove*
#
class Phase::BulkRemove < Phase::BulkOperation

  include Record::Sti::Leaf

  # ===========================================================================
  # :section: Phase::BulkOperation overrides
  # ===========================================================================

  protected

  # Operations for removing entries in bulk.
  #
  # @param [Symbol, Any] prev_state
  # @param [Hash]        opt
  #
  # @raise [ActiveRecord::RecordInvalid]    Action record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Action record creation halted.
  #
  # @return [Boolean]
  #
  def run_sequence(prev_state = nil, **opt)
    # Tracking record for batch(es) of removals from the manifest.
    action = generate_action(:BatchUnStore, manifest: manifest)

    succeeded = false # TODO: bulk-remove sequence

    aborted! unless succeeded
    succeeded
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the type of the Model instance.
  #
  # @return [String]
  #
  def self.describe_type(...)
    'BULK DELETE' # TODO: I18n
  end

end

__loading_end(__FILE__)
