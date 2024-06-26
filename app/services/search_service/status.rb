# app/services/search_service/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Health status interface.
#
module SearchService::Status

  include ApiService::Status

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A sample ISBN search and minimum number of expected results.
  #
  # @type [Hash{Symbol=>any}]
  #
  SAMPLE_ISBN_SEARCH = {
    parameters: { q: 'interdimensional' },
    expected:   ->(result) { result.records.size >= 2 }
  }.freeze

  # ===========================================================================
  # :section: ApiService::Status overrides
  # ===========================================================================

  public

  # Indicate whether the service is operational.
  #
  # @param [Hash] with
  # @param [Proc] expect
  #
  # @return [Array(TrueClass,nil)]
  # @return [Array(FalseClass,String)]
  #
  def active_status(with: nil, expect: nil)
    with   ||= SAMPLE_ISBN_SEARCH[:parameters]
    expect ||= SAMPLE_ISBN_SEARCH[:expected]
    result   = SearchService.new.get_records(**with)
    active   = result.respond_to?(:records) && expect.(result)
    message  = result&.error_message
    return active, message
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
