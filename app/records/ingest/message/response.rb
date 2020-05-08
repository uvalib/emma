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

  schema do
    has_many :messages, Array
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Api::Record, Hash, String, nil] src
  # @param [Hash]                                              opt
  #
  # This method overrides:
  # @see Api::Record#initialize
  #
  def initialize(src, **opt)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      initialize_attributes
      if src.present?
        super(src, **opt)
      elsif exception.is_a?(Api::Error)
        self.messages += exception.messages
      elsif exception.is_a?(Exception)
        self.messages << exception.message
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Strategy for pre-wrapping message data before de-serialization.
  #
  # @type [Hash{Symbol=>String,TrueClass,FalseClass}]
  #
  WRAP_FORMATS = { xml: true, json: %q({"message":%{data}}) }.freeze

  # Update *opt[:wrap]* according to the supplied formats.
  #
  # @param [Hash] opt                 May be modified.
  #
  # @return [void]
  #
  # This method overrides:
  # @see Ingest::Api::Message#apply_wrap!
  #
  def apply_wrap!(opt)
    super(opt, WRAP_FORMATS)
  end

end

__loading_end(__FILE__)
