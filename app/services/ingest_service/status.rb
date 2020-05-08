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

  # A sample ISBN search and minimum number of expected results.
  #
  # @type [Hash{Symbol=>*}]
  #
  SAMPLE_ISBN_SEARCH = {
    parameters: { q: '9781627937269' },
    expected:   ->(result) { result.records.size >= 5 }
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the service is operational.
  #
  # @param [Hash] with
  # @param [Proc] expect
  #
  # This method overrides:
  # @see ApiService::Status#active?
  #
  def active?(with: nil, expect: nil)
    with   ||= SAMPLE_ISBN_SEARCH[:parameters]
    expect ||= SAMPLE_ISBN_SEARCH[:expected]
    result = IngestService.new.get_records(**with)
    result.respond_to?(:records) && expect.(result)
  end

end

__loading_end(__FILE__)
