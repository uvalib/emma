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

  include Emma::Json

  schema do
    has_many :messages, String
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
  def initialize(src, **opt)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      super(src, **opt)
      if exception
        ex  = exception
        err = ex.respond_to?(:messages) ? ex.messages : Array.wrap(ex.message)
        self.messages += err
        self.messages.uniq!
        @errors = make_error_table(err)
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # errors
  #
  # @return [Hash{Integer=>String}]
  #
  def errors
    @errors ||= make_error_table
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # make_error_tables
  #
  # @param [Array<String>, nil] entries   Default: `#messages`.
  #
  # @return [Hash{Integer=>String}]
  #
  def make_error_table(entries = nil)
    Array.wrap(entries || messages).map { |entry|
      identifier, message = entry.split(' - ', 2)
      [identifier, message] if message.present?
    }.compact.to_h
  end

  # ===========================================================================
  # :section: Ingest::Api::Message overrides
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
