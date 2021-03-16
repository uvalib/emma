# app/records/ingest/message/ingestion_record_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# List of metadata ingestion records.
#
# @attr [Array<Ingest::Record::IngestionRecord>] records
#
# @see https://app.swaggerhub.com/apis/kden/emma-federated-ingestion-api/0.0.3#/IngestionRecordList                     Ingest API documentation
# @see https://api.swaggerhub.com/apis/kden/emma-federated-ingestion-api/0.0.3#/components/schemas/IngestionRecordList  JSON schema specification
#
class Ingest::Message::IngestionRecordList < Ingest::Api::Message

  schema do
    has_many :records, Ingest::Record::IngestionRecord
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
  def initialize(src, **opt)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      super(src, **opt)
    end
  end
=end

  # ===========================================================================
  # :section: Ingest::Api::Message overrides
  # ===========================================================================

  protected

  # Strategy for pre-wrapping message data before de-serialization.
  #
  # @type [Hash{Symbol=>String,Boolean}]
  #
  WRAP_FORMATS = { xml: true, json: %q({"records":%{data}}) }.freeze

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
