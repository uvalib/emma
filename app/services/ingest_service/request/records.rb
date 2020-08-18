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
  # @param [Array<Ingest::Message::IngestionRecordList, ::Api::Record>] records
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
    opt[:method] ||= __method__
    records = records.flat_map { |record| record_list(record) }
    api_send(:put, 'records', records, **opt)
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
    opt[:method] ||= __method__
    ids = ids.flat_map { |id| identifier_list(id) }
    api_send(:post, 'recordDeletes', ids, **opt)
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
    opt[:method] ||= __method__
    ids = ids.flat_map { |id| identifier_list(id) }
    api_send(:post, 'recordGets', ids, **opt)
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

  # Send to the Ingest API unless no items were given.
  #
  # @param [Symbol]      verb         One of :get, :post, :put, :delete
  # @param [String]      endpoint     Service path.
  # @param [Array]       body         Passed to #api as :body.
  # @param [Hash]        opt          Passed to #api.
  #
  # @option opt [Symbol] :meth        Calling method.
  #
  def api_send(verb, endpoint, body, **opt)
    body = Array.wrap(body).compact.uniq
    if body.present?
      opt[:no_raise] = true unless opt.key?(:no_raise)
      opt[:body]     = body
      api(verb, endpoint, **opt)
    else
      meth = opt[:method] || __method__
      Log.info { "#{meth}: no records" }
      @response  = nil
      @exception = IngestService::NoInputError.new
    end
  end

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
    result =
      case record
        when Ingest::Message::IngestionRecordList
          record.records
        when Ingest::Record::IngestionRecord
          record
        when ::Api::Record, Upload, Hash
          Ingest::Record::IngestionRecord.new(record)
        else
          Log.warn { "#{__method__}: unexpected: #{record.inspect}" }
      end
    Array.wrap(result)
  end

  # Generate an array of ingest identifiers.
  #
  # @param [Ingest::Message::IdentifierRecordList, Ingest::Record::IdentifierRecord, ::Api::Record, Upload, Hash, String] item
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
  #   @param [String] item
  #
  def identifier_list(item)
    # noinspection RubyYardParamTypeMatch
    result =
      case item
        when Ingest::Message::IdentifierRecordList
          item.identifiers
        when Ingest::Record::IdentifierRecord
          item
        when ::Api::Record, Upload
          Ingest::Record::IdentifierRecord.new(item)
        when Hash, String
          identifier_records(item)
        else
          Log.warn { "#{__method__}: unexpected: #{item.inspect}" }
      end
    Array.wrap(result)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  INGEST_ID_FIELDS = %i[
    emma_repository
    emma_repositoryRecordId
    emma_formatVersion
    dc_format
  ].freeze

  # Generate records.
  #
  # @param [Hash, String] item
  #
  # @return [Array<Ingest::Record::IdentifierRecord>]
  #
  # == Usage Notes
  # If the only piece of information available is the repository ID (and since
  # the repository is implicitly "emma"), this method will return with records
  # for each possible variation.  E.g. for item == "u5eed3496l10", will return
  # IdentifierRecords associated with:
  #
  #   "emma-u5eed3496l10-brf"
  #   "emma-u5eed3496l10-daisy"
  #   "emma-u5eed3496l10-daisyAudio"
  #   ...
  #
  # etc.
  #
  def identifier_records(item)
    result = []
    case item
      when Hash   then attr = item.symbolize_keys
      when /-\*$/ then attr = { emma_repositoryRecordId: item }
      when /-/    then attr = { emma_recordId: item }
      else             attr = { emma_repositoryRecordId: item }
    end
    attr.compact!
    if attr[:emma_recordId]
      attr.slice!(:emma_recordId)
      result = [attr]
    elsif attr[:emma_repositoryRecordId] && attr[:dc_format]
      attr[:emma_repository] ||= EmmaRepository.default
      attr.slice!(*INGEST_ID_FIELDS)
      result = [attr]
    elsif (rid = attr[:emma_repositoryRecordId])
      repo = format = nil
      if rid.include?('-')
        repo, rid, format = rid.split('-')
        format = nil if format == '*'
        attr[:emma_repositoryRecordId] = rid
      end
      attr[:emma_repository] ||= repo || EmmaRepository.default
      attr.slice!(*INGEST_ID_FIELDS)
      format = Array.wrap(format).presence || DublinCoreFormat.values
      result = format.map { |fmt| attr.merge(dc_format: fmt) }
    end
    result.map { |v|
      next unless allowed_record_id?(v[:emma_recordId])
      next unless allowed_repository_id?(v[:emma_repositoryRecordId])
      Ingest::Record::IdentifierRecord.new(v)
    }.compact
  end

  # Indicate whether the value appears to be acceptable as a repository ID.
  #
  # If it's all digits then it's a database record ID.
  #
  # @param [String, nil] value
  #
  def allowed_repository_id?(value)
    # noinspection RubyNilAnalysis
    value.nil? || (value.present? && !value.match?(/^\d+$/))
  end

  # Indicate whether the value appears to be acceptable as a index record ID.
  #
  # @param [String, nil] value
  #
  def allowed_record_id?(value)
    return true if value.nil?
    # noinspection RubyNilAnalysis
    repo, rid, fmt = value.split('-')
    repo.present? && rid.present? && !rid.match?(/^\d+$/) && fmt.present?
  end

end

__loading_end(__FILE__)
