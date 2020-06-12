# app/services/concerns/ingest_service/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Health status interface.
#
module IngestService::Status

  def self.included(base)
    base.send(:extend, self)
  end

  include ApiService::Status

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A sample service access and minimum number of expected results.
  #
  # @type [Hash{Symbol=>*}]
  #
  SAMPLE_REPOSITORY_ID_ACCESS= {
    ids:      'emma-2931211-pdf',
    expected: ->(result) { result.records.size == 1 }
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the service is operational.
  #
  # @param [String, Array<String>] with
  # @param [Proc]                  expect
  #
  # @return [Array<(TrueClass,nil)>]
  # @return [Array<(FalseClass,String)>]
  #
  # This method overrides:
  # @see ApiService::Status#active_status
  #
  def active_status(with: nil, expect: nil)
    with   ||= SAMPLE_REPOSITORY_ID_ACCESS[:ids]
    expect ||= SAMPLE_REPOSITORY_ID_ACCESS[:expected]
    result   = IngestService.new.get_records(*with)
    active   = result.respond_to?(:records) && expect.(result)
    message  = result&.error_message
    return active, message
  end

end

__loading_end(__FILE__)