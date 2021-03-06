# app/services/search_service/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Health status interface.
#
module SearchService::Status

  # @private
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
  # @return [(TrueClass,nil)]
  # @return [(FalseClass,String)]
  #
  def active_status(with: nil, expect: nil)
    with   ||= SAMPLE_ISBN_SEARCH[:parameters]
    expect ||= SAMPLE_ISBN_SEARCH[:expected]
    result   = SearchService.new.get_records(**with)
    active   = result.respond_to?(:records) && expect.(result)
    message  = result&.error_message
    return active, message
  end

end

__loading_end(__FILE__)
