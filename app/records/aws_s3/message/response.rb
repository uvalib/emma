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

  include AwsS3::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
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
  # @param [Array<AwsS3::Message::SubmissionRequest,Model,String>, nil] src
  # @param [Array<AwsS3::Message::SubmissionRequest,String>, nil]       sent
  # @param [Hash]                                                       opt
  #
  def initialize(src, sent = nil, **opt)
    # noinspection RubyScope, RubyMismatchedArgumentType
    create_message_wrapper(opt) do |opt|
      super(nil, opt)
      self.succeeded = sids_for(sent)
      self.failed    = sids_for(src) - succeeded
      self.messages.concat(failed.map { "#{_1} failed" })
      initialize_exec_report(messages, exception)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Translate one or more objects or strings into submission ID's.
  #
  # @param [AwsS3::Message::SubmissionRequest, String, Symbol, Array, nil] src
  #
  # @return [Array<String>]
  #
  def sids_for(src)
    Array.wrap(src).compact_blank.map! { _1.try(:submission_id) || _1.to_s }
  end

  # ===========================================================================
  # :section: Api::Message overrides
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
