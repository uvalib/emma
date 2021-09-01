# app/records/aws_s3/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for outbound deposits to an AWS S3 bucket.
#
class AwsS3::Api::Message < AwsS3::Api::Record

  include Api::Message

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Api::Record, Hash, nil] src
  # @param [Hash]                   opt
  #
  def initialize(src, opt = nil)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      initialize_attributes(src) unless src.is_a?(Api::Record)
      super(src, **opt)
    end
  end

end

__loading_end(__FILE__)
