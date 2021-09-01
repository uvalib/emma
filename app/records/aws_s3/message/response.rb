# app/records/aws_s3/message/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AwsS3::Message::Response
#
# @attr [Array<String>] messages
#
class AwsS3::Message::Response < AwsS3::Api::Message

  include Api::Shared::ErrorTable
  include Emma::Json

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :submissions, AwsS3::Message::SubmissionPackage
    has_many :succeeded
    has_many :failed
    has_many :messages
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Array<AwsS3::Message::SubmissionPackage, Upload, Hash>, nil]  src
  # @param [Array<AwsS3::Message::SubmissionPackage,String>, nil]         sent
  # @param [Hash]                                                         opt
  #
  def initialize(src, sent = nil, **opt)
    # noinspection RubyScope, RubyMismatchedParameterType
    create_message_wrapper(opt) do |opt|
      super(nil, **opt)
      self.submissions = AwsS3::Message::SubmissionPackage.to_a(src)
      self.succeeded   = sids_for(sent || submissions)
      self.failed      = sids_for(submissions) - succeeded
      self.messages   += failed.map { |sid| "#{sid} failed" }
      initialize_error_table(messages, exception)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Translate one or more objects or strings into submission ID's.
  #
  # @param [AwsS3::Message::SubmissionPackage, String, Symbol, Array, nil] src
  #
  # @return [Array<String>]
  #
  def sids_for(src)
    Array.wrap(src).map { |v|
      v.try(:submission_id) || v.to_s if v.present?
    }.compact
  end

  # ===========================================================================
  # :section: AwsS3::Api::Message overrides
  # ===========================================================================

  protected

  # Strategy for pre-wrapping message data before de-serialization.
  #
  # @type [Hash{Symbol=>String,Boolean}]
  #
  WRAP_FORMATS = { xml: true, json: %q({"messages":%{data}}) }.freeze

  # Update *opt[:wrap]* according to the supplied formats.
  #
  # @param [Hash] opt                 May be modified.
  #
  # @return [void]
  #
  def apply_wrap!(opt)
    super(opt, WRAP_FORMATS)
  end

end

__loading_end(__FILE__)
