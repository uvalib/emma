# app/records/ingest/message/identifier_record_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# List of identifier records.
#
# @attr [Array<Ingest::Record::IdentifierRecord>] identifiers
#
# @see https://app.swaggerhub.com/apis/bus/emma-federated-ingestion-api/0.0.5#/IdentifierRecordList                    Ingest API documentation
# @see https://api.swaggerhub.com/apis/bus/emma-federated-ingestion-api/0.0.5#/components/schemas/IdentifierRecordList JSON schema specification
#
class Ingest::Message::IdentifierRecordList < Ingest::Api::Message

  include Ingest::Shared::CollectionMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Ingest::Record::IdentifierRecord

  schema do
    has_many :identifiers, LIST_ELEMENT
  end

  # ===========================================================================
  # :section: Api::Message overrides
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
  def apply_wrap!(opt)
    super(opt, WRAP_FORMATS)
  end

end

__loading_end(__FILE__)
