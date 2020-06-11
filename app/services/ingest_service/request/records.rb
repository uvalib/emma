# app/services/ingest_service/request/records.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# IngestService::Records
#
module IngestService::Request::Records

  include IngestService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == PUT /records
  # EMMA Federated Ingestion.
  #
  # Inserts or updates one or more metadataRecords in the search index. For
  # the "upsert" operation, if no such record exists for the emma_repository,
  # emma_repositoryRecordId, dc_format, and (optionally) emma_formatVersion, a
  # record is created. Otherwise the existing record is updated.
  #
  # The number of records to be updated at once is capped at 1000.
  #
  # @param [Ingest::Message::IngestionRecordList, Array<::Api::Record>] records
  # @param [Hash] opt                 Passed to #api.
  #
  # @return [Ingest::Message::Response]
  #
  # == Variations
  #
  # @overload put_records(list, **opt)
  #   @param [Ingest::Message::IngestionRecordList] list
  #   @param [Hash]                                 opt       Passed to #api.
  #
  # @overload put_records(*records, **opt)
  #   @param [Array<::Api::Record>]                 records
  #   @param [Hash]                                 opt       Passed to #api.
  #
  # == HTTP response codes
  # 202 Accepted        Items accepted for update.
  # 207 Multi-Status    Some items inserted or updated.
  # 400 Bad Request     Invalid input.
  #
  # @see https://app.swaggerhub.com/apis/kden/emma-federated-ingestion-api
  # @see https://api.swaggerhub.com/apis/kden/emma-federated-ingestion-api/0.0.3#/paths//records
  #
  def put_records(*records, **opt)
    opt[:no_raise] = true
    opt[:body] = records.flat_map { |record| record_list(record) }.compact.uniq
    api(:put, 'records', **opt)
    Ingest::Message::Response.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # == POST /recordDeletes
  #
  # Deletes one or more metadataRecords in the search index. Records are
  # uniquely identified by the emma_repository, emma_repositoryRecordId,
  # dc_format, and (optionally) emma_formatVersion.
  #
  # The number of records to be deleted at once is capped at 1000.
  #
  # @param [Ingest::Message::IngestionRecordList, Array<::Api::Record>, Array<String>] ids
  # @param [Hash] opt                 Passed to #api.
  #
  # @return [Ingest::Message::Response]
  #
  # == Variations
  #
  # @overload delete_records(list, **opt)
  #   @param [Ingest::Message::IdentifierRecordList] list
  #
  # @overload delete_records(*records, **opt)
  #   @param [Array<::Api::Record>] records
  #
  # @overload delete_records(*ids, **opt)
  #   @param [Array<String>] ids
  #
  # === HTTP response codes
  # 202 Accepted        Items accepted for deletion.
  # 207 Multi-Status    Some items deleted.
  # 400 Bad Request     Invalid input.
  #
  # @see https://app.swaggerhub.com/apis/kden/emma-federated-ingestion-api
  # @see https://api.swaggerhub.com/apis/kden/emma-federated-ingestion-api/0.0.3#/paths//recordDeletes
  #
  def delete_records(*ids, **opt)
    opt[:no_raise] = true
    opt[:body] = ids.flat_map { |id| identifier_list(id) }.compact.uniq
    api(:post, 'recordDeletes', **opt)
    Ingest::Message::Response.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # == POST /recordGets
  #
  # Retrieves one or more metadataRecords in the search index. Records are
  # uniquely identified by the emma_repository, emma_repositoryRecordId,
  # dc_format, and (optionally) emma_formatVersion.
  #
  # The number of records to be retrieved at once is capped at 1000.
  #
  # @param [Ingest::Message::IngestionRecordList, Array<Api::Record>, Array<String>] ids
  # @param [Hash] opt                 Passed to #api.
  #
  # @return [Search::Message::SearchRecordList]
  #
  # == Variations
  #
  # @overload get_records(list, **opt)
  #   @param [Ingest::Message::IdentifierRecordList] list
  #
  # @overload get_records(*records, **opt)
  #   @param [Array<::Api::Record>] records
  #
  # @overload get_records(*ids, **opt)
  #   @param [Array<String>] ids
  #
  # === HTTP response codes
  # 200 OK              Items retrieved.
  # 400 Bad Request     Invalid input.
  #
  # @see https://app.swaggerhub.com/apis/kden/emma-federated-ingestion-api
  # @see https://api.swaggerhub.com/apis/kden/emma-federated-ingestion-api/0.0.3#/paths//recordGets
  #
  def get_records(*ids, **opt)
    opt[:no_raise] = true
    opt[:body] = ids.flat_map { |id| identifier_list(id) }.compact.uniq
    api(:post, 'recordGets', **opt)
    Search::Message::SearchRecordList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate an array of ingest records.
  #
  # @param [Ingest::Message::IngestionRecordList, Ingest::Record::IngestionRecord, ::Api::Record, Upload, Hash] record
  #
  # @return [Array<Ingest::Record::IngestionRecord>]
  #
  # == Variations
  #
  # @overload record_list(list)
  #   @param [Ingest::Message::IngestionRecordList] list
  #
  # @overload record_list(record)
  #   @param [Ingest::Record::IngestionRecord] record
  #
  # @overload record_list(record)
  #   @param [::Api::Record, Upload, Hash] record
  #
  def record_list(record)
    # noinspection RubyYardReturnMatch
    case record
      when Ingest::Message::IngestionRecordList
        record.records
      when Ingest::Record::IngestionRecord
        [record]
      else
        [Ingest::Record::IngestionRecord.new(record)]
    end
  end

  # Generate an array of ingest identifiers.
  #
  # @param [Ingest::Message::IdentifierRecordList, Ingest::Record::IdentifierRecord, ::Api::Record, Upload, Hash, String] id
  #
  # @return [Array<Ingest::Record::IdentifierRecord>]
  #
  # == Variations
  #
  # @overload identifier_list(list)
  #   @param [Ingest::Message::IdentifierRecordList] list
  #
  # @overload identifier_list(record)
  #   @param [Ingest::Record::IdentifierRecord] record
  #
  # @overload identifier_list(record)
  #   @param [::Api::Record, Upload, Hash] record
  #
  # @overload identifier_list(id)
  #   @param [String] id
  #
  def identifier_list(id)
    # noinspection RubyYardReturnMatch
    case id
      when Ingest::Message::IdentifierRecordList
        id.identifiers
      when Ingest::Record::IdentifierRecord
        [id]
      when ::Api::Record, Upload, Hash
        [Ingest::Record::IdentifierRecord.new(id)]
      else
        [Ingest::Record::IdentifierRecord.new(nil, value: id)]
    end
  end

end

__loading_end(__FILE__)
