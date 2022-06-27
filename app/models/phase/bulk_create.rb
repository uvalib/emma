# app/models/phase/bulk_create.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bulk entry creation workflow tracking record.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.phase.bulk_create*
#
class Phase::BulkCreate < Phase::BulkOperation

  include Record::Sti::Leaf

  # ===========================================================================
  # :section: Phase::BulkOperation overrides
  # ===========================================================================

  protected

  # Operations for creating entries in bulk.
  #
  # @param [Symbol, Any] prev_state
  # @param [Hash]        opt
  #
  # @raise [ActiveRecord::RecordInvalid]    Action record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Action record creation halted.
  #
  # @return [Boolean]
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def run_sequence(prev_state = nil, **opt)
    # Tracking record for batch(es) of uploads from the manifest.
    action = generate_action(:BatchStore, manifest: manifest)

    succeeded = false # TODO: bulk-create sequence

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
    'BULK UPLOAD' # TODO: I18n
  end

end

__loading_end(__FILE__)
