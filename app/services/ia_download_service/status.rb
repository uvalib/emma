# app/services/concerns/ia_download_service/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Health status interface.
#
module IaDownloadService::Status

  def self.included(base)
    base.send(:extend, self)
  end

  include ApiService::Status

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin
  # A sample ISBN search and minimum number of expected results.
  #
  # @type [Hash{Symbol=>*}]
  #
  SAMPLE_ISBN_SEARCH = {
    parameters: { q: 'interdimensional' },
    expected:   ->(result) { result.records.size >= 2 }
  }.freeze
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin
  # Indicate whether the service is operational.
  #
  # @param [Hash] with
  # @param [Proc] expect
  #
  # @return [Array<(TrueClass,nil)>]
  # @return [Array<(FalseClass,String)>]
  #
  # This method overrides:
  # @see ApiService::Status#active_status
  #
  def active_status(with: nil, expect: nil)
    with   ||= SAMPLE_ISBN_SEARCH[:parameters]
    expect ||= SAMPLE_ISBN_SEARCH[:expected]
    result   = IaDownloadService.new.get_records(**with)
    active   = result.respond_to?(:records) && expect.(result)
    message  = result&.error_message
    return active, message
  end
=end

end

__loading_end(__FILE__)
