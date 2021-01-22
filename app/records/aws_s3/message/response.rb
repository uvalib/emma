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

  schema do
    has_many :messages
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Api::Record, Hash, nil] src
  # @param [Hash]                   opt
  #
  def initialize(src, **opt)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      super(src, **opt)
      # noinspection RubyYardParamTypeMatch
      initialize_error_table(messages, exception)
    end
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
