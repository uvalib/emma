# app/records/ingest/message/identifier_record_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Ingest::Message::IdentifierRecordList
#
# @attr [Array<Ingest::Record::IdentifierRecord>] identifiers
#
# @see https://api.swaggerhub.com/apis/kden/emma-federated-ingestion-api/0.0.3#/components/schemas/IdentifierRecordList
#
class Ingest::Message::IdentifierRecordList < Ingest::Api::Message

  schema do
    has_many :identifiers, Ingest::Record::IdentifierRecord
  end

=begin
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
      super(src, **opt)
    end
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Strategy for pre-wrapping message data before de-serialization.
  #
  # @type [Hash{Symbol=>String,Boolean}]
  #
  WRAP_FORMATS = { xml: true, json: %q({"identifiers":%{data}}) }.freeze

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
