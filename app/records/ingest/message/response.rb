# app/records/ingest/message/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Ingest::Message::Response
#
# @attr [Array<String>] messages
#
class Ingest::Message::Response < Ingest::Api::Message

  include Ingest::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :messages, String
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Model, Hash, String, nil] src
  # @param [Hash, nil]                                   opt
  #
  def initialize(src, opt = nil)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      super(nil, opt)
      initialize_exec_report(exception)
      self.messages.concat(exec_report.error_messages)
    end
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
