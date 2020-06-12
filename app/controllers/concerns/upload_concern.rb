# app/controllers/concerns/upload_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/http'

# UploadConcern
#
module UploadConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'UploadConcern')
  end

  include IngestConcern
  include ParamsHelper
  include FlashHelper
  include Emma::Csv

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  MIME_REGISTRATION =
    FileNaming.format_classes.values.each(&:register_mime_types)

  # ===========================================================================
  # :section: Classes
  # ===========================================================================

  public

  # Exception raised when a submission is incomplete or invalid.
  #
  class SubmitError < StandardError

    # Initialize a new instance.
    #
    # @param [String, nil] msg
    #
    # This method overrides:
    # @see StandardError#initialize
    #
    def initialize(msg = nil)
      super(msg || 'unknown') # TODO: I18n
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # POST/PUT/PATCH parameters from the upload form that are not relevant to the
  # create/update of an Upload instance.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_UPLOAD_FORM_PARAMETERS = %i[limit field-control].sort.freeze

  # Extract POST parameters that are usable for creating/updating an Upload
  # instance.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [Hash{Symbol=>String}]
  #
  # == Implementation Notes
  # The value `params[:upload][:emma_data]` is ignored because it reports the
  # original metadata values that were supplied to the edit form.  The value
  # `params[:upload][:file]` is ignored if it is blank or is the JSON
  # representation of an empty object ("{}") -- this indicates an editing
  # submission where metadata is being changed but the uploaded file is not
  # being replaced.
  #
  def upload_post_parameters(p = nil)
    result = url_parameters(p).except!(*IGNORED_UPLOAD_FORM_PARAMETERS)
    result.deep_symbolize_keys!
    upload = result.delete(:upload) || {}
    file   = upload[:file]
    result[:file_data] = file unless file.blank? || (file == '{}')
    result[:base_url]  = request.base_url
    reject_blanks(result)
  end

  # Extract POST parameters and data for bulk operations.
  #
  # @param [ActionController::Parameters, Hash] p   Default: `#url_parameters`.
  # @param [ActionDispatch::Request]            req Default: `#request`.
  #
  # @return [Array<Hash>]
  #
  def bulk_post_parameters(p = nil, req = nil)
    prm = url_parameters(p).except!(*IGNORED_UPLOAD_FORM_PARAMETERS)
    prm.deep_symbolize_keys!
    @force = true?(prm[:force])
    src    = prm[:src] || prm[:source]
    opt    = src ? { src: src } : { data: (req || request) }
    # noinspection RubyYardReturnMatch
    fetch_data(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Remote or locally-provided data.
  #
  # @param [Hash] opt
  #
  # @option opt [String]       :src   URI or path to file containing the data.
  # @option opt [String, Hash] :data  Literal data.
  #
  # @raise [StandardError]            If both *src* and *data* are present.
  #
  # @return [nil]                     If both *src* and *data* are missing.
  # @return [Hash]
  # @return [Array<Hash>]
  #
  def fetch_data(**opt)
    src  = opt[:src].presence
    data = opt[:data].presence
    if data
      raise "#{__method__}: both :src and :data were given" if src
      name = nil
    elsif src.is_a?(ActionDispatch::Http::UploadedFile)
      name = src.original_filename
      data = src
    elsif src
      name = src
      data =
        case name
          when /^https?:/ then Faraday.get(src)   # Remote file URI.
          when /\.csv$/   then src                # Local CSV file path.
          else                 File.read(src)     # Local JSON file path.
        end
    else
      return Log.warn { "#{__method__}: neither :data nor :src given" }
    end
    case name.to_s.downcase.split('.').last
      when 'json' then json_parse(data)
      when 'csv'  then csv_parse(data)
      else             json_parse(data) || csv_parse(data)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Process inserted or updated Upload records.
  #
  # @param [Array<Upload,Array<Upload>>] items  @see #collect_items
  #
  # @return [Array<(Array,Array)>]    Succeeded names and failed record IDs.
  #
  # @see #add_to_index
  #
  def finalize_upload(*items)
    items, failed = collect_items(*items)
    _, failed = add_to_index(*items) unless failed.present?
    succeeded = items.map { |i| "#{i.repository_id} (#{i.filename})" }
    return succeeded, failed
  end

  # destroy_upload
  #
  # @param [Array<Upload,String,Array>] items   @see #collect_items
  # @param [Boolean]                    force   Force removal of index entries
  #                                               even if the related database
  #                                               entries do not exist.
  #
  # @return [Array<(Array,Array)>]    Succeeded paths and failed record IDs.
  #
  # @see #remove_from_index
  #
  def destroy_upload(*items, force: false)
    items, failed = collect_items(*items, force: force)
    _, failed = remove_from_index(*items) unless failed.present?
    items = [] if failed.present?
    succeeded =
      items.map { |item|
        if !item.is_a?(Upload)
          "item #{item.inspect}" # TODO: I18n
        elsif !item.destroy
          failed << item.repository_id and next
        else
          item.repository_id
        end
      }.compact
    return succeeded, failed
  end

  # ===========================================================================
  # :section: Index ingest operations
  # ===========================================================================

  public

  # As a convenience for testing, sending to the Federated Search Ingest API
  # can be short-circuited here.  The value should be *false* normally.
  #
  # @type [Boolean]
  #
  DISABLE_UPLOAD_INDEX_UPDATE = true?(ENV['DISABLE_UPLOAD_INDEX_UPDATE'])

  # Add the indicated items from the EMMA Unified Index.
  #
  # @param [Array<Upload>] items
  #
  # @raise [StandardError] @see IngestService::Request::Records#put_records
  #
  # @return [Array<(Array,Array)>]    Succeeded names and failed names.
  #
  def add_to_index(*items)
    succeeded = failed = [] # TODO: extract failed from API message
    if items.present?
      result = ingest_api.put_records(*items)
      fail(result.exception) if result.exception.present?
      succeeded = items.map(&:id)
    end
    return succeeded, failed
  end

  # Remove the indicated items from the EMMA Unified Index.
  #
  # @param [Array<Upload>] items
  #
  # @raise [StandardError] @see IngestService::Request::Records#delete_records
  #
  # @return [Array<(Array,Array)>]    Succeeded names and failed names.
  #
  def remove_from_index(*items)
    succeeded = failed = [] # TODO: extract failed from API message
    if items.present?
      result = ingest_api.delete_records(*items)
      fail(result.exception) if result.exception.present?
      succeeded = items.map { |item| item.respond_to?(:id) ? item.id : item }
    end
    return succeeded, failed
  end

  # Override the normal methods if Unified Search update is disabled.

  if DISABLE_UPLOAD_INDEX_UPDATE

    %i[add_to_index remove_from_index].each do |m|
      send(:define_method, m) { |*items| skip_index_ingest(m, *items) }
    end

    def skip_index_ingest(method, *items)
      __debug { "*** SKIPPING *** #{method} | items = #{items.inspect}" }
      succeeded = items.map { |item| item.respond_to?(:id) ? item.id : item }
      failed    = []
      return succeeded, failed
    end

  end

  # ===========================================================================
  # :section: Bulk operations
  # ===========================================================================

  public

  # Bulk uploads.
  #
  # @param [Array<Hash,Upload>] entries
  # @param [Hash]               opt     Passed to #bulk_records.
  #
  # @return [Array<(Array,Array)>]      Succeeded entries and failed entries.
  #
  # @see ActiveRecord::Persistence::ClassMethods#insert_all
  # @see #bulk_add_to_index
  #
  def bulk_create(entries, **opt)
    records = bulk_records(entries, **opt)
    result  = Upload.insert_all(records.map(&:attributes))
    bulk_add_to_index(result, entries, records)
  end

  # Bulk modifications.
  #
  # @param [Array<Hash,Upload>] entries
  # @param [Hash]               opt     Passed to #bulk_records.
  #
  # @return [Array<(Array,Array)>]      Succeeded entries and failed entries.
  #
  # @see ActiveRecord::Persistence::ClassMethods#upsert_all
  # @see #bulk_add_to_index
  #
  def bulk_update(entries, **opt)
    records = bulk_records(entries, **opt)
    result  = Upload.upsert_all(entries.map(&:attributes))
    bulk_add_to_index(result, entries, records)
  end

  # Bulk removal.
  #
  # @param [Array<Upload,String,Integer,Array>] id_specs
  #
  # @return [Array<(Array,Array)>]    Succeeded entries and failed entries.
  #
  # @see ActiveRecord::Persistence::ClassMethods#delete
  # @see #bulk_remove_from_index
  #
  def bulk_destroy(id_specs, **)
    ids    = Upload.collect_ids(id_specs)
    result = Upload.delete(ids)
    bulk_remove_from_index(result, ids)
  end

  # ===========================================================================
  # :section: Bulk operations
  # ===========================================================================

  protected

  # Fallback URL base. TODO: ?
  #
  # @type [String]
  #
  BULK_BASE_URL = 'https://emmadev.internal.lib.virginia.edu'

  # Default user for bulk uploads. # TODO: ?
  #
  # @type [String]
  #
  BULK_USER = 'emmadso@bookshare.org'

  # File to use as a placeholder if no file was given for the upload.
  #
  # If *false* or *nil* then #upload_record will raise an exception if no file
  # was given.
  #
  # @type [String, FalseClass, NilClass]
  #
  BULK_PLACEHOLDER_FILE =
    if application_deployed?
      "#{BULK_BASE_URL}/placeholder.pdf"
    else
      'http://localhost:3000/placeholder.pdf'
    end

  # Prepare entries for bulk insert/upsert to the database, ensuring that all
  # associated files have been copied into storage.
  #
  # @param [Array<Hash,Upload>] entries
  # @param [String]             base_url
  # @param [User, String]       user
  # @param [Integer]            limit     Only the first *limit* records.
  # @param [Hash]               opt       Optional added fields.
  #
  # @return [Array<Upload>]
  #
  def bulk_records(entries, base_url: nil, user: nil, limit: nil, **opt)
    entries = Array.wrap(entries).reject(&:blank?)
    entries = entries.take(limit) if limit.to_i > 0
    opt[:base_url]   = base_url || BULK_BASE_URL
    opt[:user_id]    = User.find_id(user || BULK_USER)
    opt[:importer] ||= Import::IaBulk # TODO: ?
    opt[:file_tot] ||= entries.size
    opt[:file_num] ||= 0
    entries.map do |entry|
      opt[:file_num] += 1
      Log.info do
        msg = "#{__method__} [#{opt[:file_num]} of #{opt[:file_tot]}]:"
        msg += " #{entry}" if entry.is_a?(Upload)
        msg
      end
      entry = upload_record(entry.merge(opt)) unless entry.is_a?(Upload)
      entry.promote_file
      entry
    end
  end

  # Create a new free-standing Upload instance.
  #
  # @param [Hash] opt                 Passed to Upload#initialize except for:
  #
  # @option opt [String] :file_path   File URI or path.
  # @option opt [Symbol] :meth        Calling method (for logging).
  #
  # @raise [StandardError]            If no :file_path was given or determined.
  #
  # @return [Upload]
  #
  # @see Upload#upload_file
  #
  def upload_record(opt)
    __debug_args(binding)
    opt, upload_opt = partition_options(opt, :file_path, :meth)
    file_path = opt[:file_path] || BULK_PLACEHOLDER_FILE
    raise "#{__method__}: No upload file provided." if file_path.blank? # TODO: I18n
    Upload.new(upload_opt.deep_symbolize_keys!).tap do |entry|
      file = entry.upload_file(file_path)
      Log.info do
        name = file&.original_filename.inspect
        type = file&.mime_type || 'unknown type'
        size = file&.size      || 0
        meth = opt[:meth]      || __method__
        "#{meth}: #{name} (#{size} bytes) #{type}"
      end
    end
  rescue => e
    Log.error { "#{__method__}: #{e.class}: #{e.message}" }
    raise e
  end

  # ===========================================================================
  # :section: Index ingest operations
  # ===========================================================================

  public

  # bulk_add_to_index
  #
  # @param [ActiveRecord::Result] result
  # @param [Array<Hash,Upload>]   entries
  # @param [Array<Upload>]        records
  #
  # @return [Array<(Array,Array)>]
  #
  # @see #add_to_index
  #
  # == Implementation Notes
  # The 'failed' portion of the method return will always be empty if using
  # MySQL because ActiveRecord::Result for bulk operations does not contain
  # useful information.
  #
  def bulk_add_to_index(result, entries, records)
    if result.columns.blank? || (result.rows.size == records.size)
      succeeded = records.map(&:repository_id)
      _, failed = add_to_index(*records)
    else
      succeeded = result.map { |r| r[:repository_id] }
      failed    = entries.reject { |e| succeeded.include?(e[:repository_id]) }
    end
    return succeeded, failed
  end

  # bulk_remove_from_index
  #
  # @param [ActiveRecord::Result] result
  # @param [Array<String>]        ids
  #
  # @return [Array<(Array,Array)>]
  #
  # @see #remove_from_index
  #
  def bulk_remove_from_index(result, ids)
    if result == ids.size
      succeeded = ids
      _, failed = remove_from_index(*ids)
    else
      succeeded = []
      failed    = ids
    end
    return succeeded, failed
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a mixture of Upload objects and record identifiers into a list of
  # Upload objects.
  #
  # @param [Array<Upload,String,Array>] items   @see Upload#collect_ids
  # @param [Boolean]                    force   See Usage Notes
  #
  # @return [Array<(Array<Upload>,Array)>]      Upload records and failed ids.
  # @return [Array<(Array<Upload,String>,[])>]  If *force* is *true*.
  #
  # == Usage Notes
  # If *force* is true, the returned list of failed records will be empty but
  # the returned list of items may contain a mixture of Upload and String
  # elements.
  #
  def collect_items(*items, force: false)
    failed = []
    items =
      items.flatten.flat_map { |item|
        next if item.blank?
        next item if item.is_a?(Upload)
        Upload.collect_ids(item).map do |identifier|
          record = Upload.get_record(identifier)
          failed << identifier unless record || force
          record || identifier
        end
      }.compact
    return items, failed
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Placeholder error message.
  #
  # @type [String]
  #
  DEFAULT_ERROR_MESSAGE = I18n.t('emma.error.default', default: 'ERROR').freeze

  # Error types and messages.
  #
  # @type [Hash{Symbol=>Array<(String,Class)>}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  UPLOAD_ERROR =
    I18n.t('emma.error.upload').transform_values { |properties|
      text = properties[:message]
      err  = properties[:error]
      err  = "Net::#{err}" if err.is_a?(String) && !err.start_with?('Net::')
      err  = err&.constantize unless err.is_a?(Module)
      err  = err.exception_type if err.respond_to?(:exception_type)
      [text, err]
    }.symbolize_keys.deep_freeze

  # Raise an exception.
  #
  # If *problem* is a symbol, it is used as a key to #UPLOAD_ERROR with *value*
  # used for string interpolation.
  #
  # Otherwise, error message(s) are extracted from *problem*.
  #
  # @param [Symbol,String,Array<String>,Exception,ActiveModel::Errors] problem
  # @param [*, nil]                                                    value
  #
  # @raise [UploadConcern::SubmitError]
  # @raise [Api::Error]
  # @raise [Net::ProtocolError]
  # @raise [StandardError]
  #
  def fail(problem, value = nil)
    err = nil
    case problem
      when Symbol              then msg, err = UPLOAD_ERROR[problem]
      when Api::Error          then msg = problem.messages
      when Exception           then msg = problem.message
      when ActiveModel::Errors then msg = problem.full_messages
      else                          msg = problem
    end
    err = SubmitError unless err.is_a?(Exception)
    msg = Array.wrap(msg)
    msg = msg.map { |t| t.to_s % value } if value
    msg = msg.join('; ').presence || DEFAULT_ERROR_MESSAGE
    raise err, msg
  end

  # Generate a response to a POST.
  #
  # @param [Symbol, Integer, Exception] status
  # @param [String, Exception]          message
  # @param [String]                     redirect
  # @param [Boolean]                    xhr       Force XHR handling.
  #
  # @return [*]
  #
  # == Variations
  #
  # @overload post_response(status, message = nil, redirect: nil, xhr: nil)
  #   @param [Symbol, Integer]   status
  #   @param [String, Exception] message
  #
  # @overload post_response(except, redirect: nil, xhr: nil)
  #   @param [Exception] except
  #
  def post_response(status, message = nil, redirect: nil, xhr: nil)
    status, message = [nil, status] if status.is_a?(Exception)
    status ||= :bad_request
    xhr      = request_xhr? if xhr.nil?
    except   = (message if message.is_a?(Exception))
    if except
      if except.respond_to?(:code)
        status = except.code || status
      elsif except.respond_to?(:response)
        status = except.response.status || status
      end
      Log.error do
        "#{__method__}: #{status}: #{except.class}: #{except.full_message}"
      end
      message = except.message
    end
    message = Array.wrap(message).map { |m| m.inspect.truncate(1024) }.presence
    unless except
      Log.info do
        [__method__, status, message&.join(', ')].compact.join(': ')
      end
    end
    if redirect || !xhr
      if %i[ok found].include?(status) || (200..399).include?(status)
        flash_success(*message)
      else
        flash_failure(*message)
      end
      if redirect
        redirect_to(redirect)
      else
        redirect_back(fallback_location: upload_index_path)
      end
    else
      message ||= DEFAULT_ERROR_MESSAGE
      message = safe_json_parse(message).to_json.truncate(1024)
      head status, 'X-Flash-Message': message
    end
  end

end

__loading_end(__FILE__)
