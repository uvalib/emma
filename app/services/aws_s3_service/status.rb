# app/services/aws_s3_service/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Health status interface.
#
module AwsS3Service::Status

  include ApiService::Status

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin # TODO: AwsS3 status?
  # A sample service access and minimum number of expected results.
  #
  # Title:  "Campbell Biology: Concepts & Connections"
  # ISBN:   "9780134296012"
  #
  # @type [Hash{Symbol=>Any}]
  #
  SAMPLE_RECORD_ID_ACCESS= {
    ids:      'emma-2931211-pdf',
    expected: ->(result) { result.records.size == 1 }
  }.freeze
=end

  # ===========================================================================
  # :section: ApiService::Status overrides
  # ===========================================================================

  public

=begin # TODO: AwsS3 status?
  # Indicate whether the service is operational.
  #
  # @param [String, Array<String>] with
  # @param [Proc]                  expect
  #
  # @return [(TrueClass,nil)]
  # @return [(FalseClass,String)]
  #
  def active_status(with: nil, expect: nil)
    with   ||= SAMPLE_RECORD_ID_ACCESS[:ids]
    expect ||= SAMPLE_RECORD_ID_ACCESS[:expected]
    result   = AwsS3Service.new.get_records(*with)
    active   = result.respond_to?(:records) && expect.(result)
    message  = result&.error_message
    return active, message
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
