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
  include FlashConcern
  include ParamsHelper
  include Emma::Csv

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  MIME_REGISTRATION =
    FileNaming.format_classes.values.each(&:register_mime_types)

  # ===========================================================================
  # :section: Modules
  # ===========================================================================

  public

  # Methods to support display of Upload instances and identifiers.
  #
  module RenderMethods

    def self.included(base)
      base.send(:extend, self)
    end

    # Methods defined in Upload and numerous subclasses of Api::Record which
    # yield the repository ID of the associated entry.
    #
    # @type [Array<Symbol>]
    #
    RID_METHODS = %i[emma_repositoryRecordId repository_id].freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Extract the database ID from the given item.
    #
    # @param [Upload, Hash, String] item
    #
    # @return [String, nil]
    #
    def db_id(item)
      # noinspection RubyCaseWithoutElseBlockInspection
      case item
        when Upload  then item.id
        when Hash    then item[:id] || item['id']
        when Integer then item
        when /^\d+$/ then item
      end.to_s.presence
    end

    # Extract the repository ID from the given item.
    #
    # @param [Api::Record, Upload, Hash, String] item
    #
    # @return [String, nil]
    #
    def repository_id(item)
      if item.is_a?(String)
        item if item.match?(/^[^\d]/)
      elsif item.is_a?(Hash)
        item[:repository_id] || item['repository_id']
      elsif (rid_method = RID_METHODS.find { |m| item.respond_to?(m) } )
        item.send(rid_method)
      end.to_s.presence
    end

    # Show the repository ID if it can be determined for the given item(s).
    #
    # @param [Api::Record, Upload, Hash, String] item
    # @param [String, nil]                       default
    #
    # @return [String, ActiveSupport::SafeBuffer]
    #
    def make_label(item, default: '(missing)') # TODO: I18n
      # noinspection RubyYardParamTypeMatch
      ident = repository_id(item) || db_id(item) || default || item.to_s
      ident = "Item #{ident}" if ident.match?(/^\d/)
      file  = (item.filename if item.is_a?(Upload))
      ident = "#{ident} (#{file})" if file.present?
      ident
    end

  end

  include RenderMethods

  # ===========================================================================
  # :section: Classes
  # ===========================================================================

  public

  # Each instance translates to a distinct line in the flash message.
  #
  class ErrorEntry < FlashHelper::Entry

    include RenderMethods

    # =========================================================================
    # :section: FlashHelper::Entry overrides
    # =========================================================================

    protected

    # Process a single object to make it a part.
    #
    # @param [*] part
    #
    # @return [String]
    #
    # This method overrides
    # @see FlashHelper::Entry#transform
    #
    def transform(part)
      make_label(part, default: '').presence || super(part)
    end

  end

  # Exception raised when a submission is incomplete or invalid.
  #
  class SubmitError < StandardError

    # Individual error messages (if the originator supplied multiple messages).
    #
    # @return [Array<String>]
    #
    attr_reader :messages

    # Initialize a new instance.
    #
    # @param [Array<String>, String, nil] msg
    #
    # This method overrides:
    # @see StandardError#initialize
    #
    def initialize(msg = nil)
      msg ||= 'unknown' # TODO: I18n
      @messages = Array.wrap(msg)
      super(@messages.first)
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
    Array.wrap(fetch_data(**opt)).map(&:symbolize_keys)
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
    __debug_args("UPLOAD #{__method__}", binding)
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

  # Add a new submission to the database, upload its file to storage, and add
  # a new index entry for it.
  #
  # @param [Upload, Hash] data
  # @param [Boolean]      atomic      If *false*, do not stop on failure.
  # @param [Boolean]      index       If *false*, do not update index.
  #
  # @option data [String] :file_path  Only if *data* is a Hash.
  #
  # @return [Array<(Upload,Array)>]   Record and error messages.
  #
  # @see #add_to_index
  #
  # Compare with:
  # @see #bulk_upload_create
  #
  def upload_create(data, atomic: true, index: true)
    __debug_args("UPLOAD #{__method__}", binding)

    # Save the Upload record to the database.
    item = db_insert(data)
    return item, item.errors if item.errors.present?

    # Include the new submission in the index.
    return item, [] unless index
    succeeded, failed, _ = add_to_index(item, atomic: atomic)
    return succeeded.first, failed
  end

  # Update an existing database record and update its associated index entry.
  #
  # @param [String, Upload] id
  # @param [Hash, nil]      data
  # @param [Boolean]        atomic    If *false*, do not stop on failure.
  # @param [Boolean]        index     If *false*, do not update index.
  #
  # @return [Array<(Upload,Array)>]   Record and error messages.
  #
  # @see #update_in_index
  #
  # Compare with:
  # @see #bulk_upload_update
  #
  def upload_update(id, data, atomic: true, index: true)
    __debug_args("UPLOAD #{__method__}", binding)

    # Fetch the Upload record and update it in the database.
    item = db_update(id, data)
    return item, item.errors if item.errors.present?

    # Update the index with the modified submission.
    return item, [] unless index
    succeeded, failed, _ = update_in_index(item, atomic: atomic)
    return succeeded.first, failed
  end

  # Remove Upload records from the database and from the index.
  #
  # @param [Array<Upload,String,Array>] items   @see #collect_records
  # @param [Boolean]                    atomic  *true* == all-or-none
  # @param [Boolean]                    index   *false* -> no index update
  # @param [Boolean]                    force   Force removal of index entries
  #                                               even if the related database
  #                                               entries do not exist.
  #
  # @return [Array<(Array,Array)>]    Succeeded items and failed item messages.
  #
  # @see #remove_from_index
  #
  # == Usage Notes
  # Atomicity of the record removal phase rests on the assumption that any
  # database problem(s) would manifest with the very first destruction attempt.
  # If a later item fails, the successfully-destroyed items will still be
  # removed from the index.
  #
  def upload_destroy(*items, atomic: true, index: true, force: false)
    __debug_args("UPLOAD #{__method__}", binding)

    # Translate entries into Upload record instances.
    items, failed = collect_records(*items, force: force)
    return [], failed if atomic && failed.present? || items.blank?

    # Remove the records from the database.
    destroyed = []
    retained  = []
    counter   = 0
    items =
      items.map { |item|
        # noinspection RubyYardParamTypeMatch
        if !item.is_a?(Upload)
          item                        # Only seen if *force* is *true*.
        elsif db_delete(item)
          # bulk_throttle(counter) # TODO: keep?
          counter += 1
          destroyed << item
          item
        elsif atomic && destroyed.blank?
          return [], [item]           # Early return with the problem item.
        else
          retained << item and next   # Will not be included in *items*.
        end
      }.compact
    if retained.present?
      Log.warn do
        msg = [__method__]
        msg << 'not atomic' if atomic
        msg << 'items retained in the database that will be de-indexed'
        msg << retained.map { |item| make_label(item) }.join(', ')
        msg.join(': ')
      end
      retained.map! { |item| ErrorEntry.new(item, 'not removed') } # TODO: I18n
    end

    # Remove the associated entries from the index.
    return items, retained unless index && items.present?
    succeeded, failed = remove_from_index(*items, atomic: atomic)
    return succeeded, (retained + failed)
  end

  # ===========================================================================
  # :section: Records
  # ===========================================================================

  public

  # A string added to the start of each title created on a non-production
  # instance to help distinguish it from other index results.
  #
  # @type [String, nil]
  #
  DEV_TITLE_PREFIX = ('RWL' unless application_deployed?)

  # The database ID for the item, or, failing that, the repository ID.
  #
  # @param [Upload, Hash, String] item
  #
  # @return [String, nil]
  #
  def identifier(item)
    db_id(item) || repository_id(item)
  end

  # Return an array of the characteristic identifiers for the item.
  #
  # @param [Upload, Hash, String] item
  #
  # @return [Array<String>]
  #
  def identifiers(item)
    [db_id(item), repository_id(item)].compact
  end

  # Return with the specified record or *nil* if one could not be found.
  #
  # @param [String, Upload] item
  # @param [Boolean]        no_raise  If *true*, do not raise exceptions.
  # @param [Symbol]         meth      Calling method (for logging).
  #
  # @raise [StandardError]            If *item* not found and !*no_raise*.
  #
  # @return [Upload]                  The item; from the database if necessary.
  # @return [nil]                     If *item* not found and *no_raise*.
  #
  def get_record(item, no_raise: false, meth: nil)
    meth ||= __method__
    # noinspection RubyYardReturnMatch
    if item.blank?
      fail(:file_id) unless no_raise
    elsif (result = find_records(item).first).is_a?(Upload)
      result
    elsif no_raise
      Log.warn  { "#{meth}: #{item}: skipping record" }
    else
      Log.error { "#{meth}: #{item}: non-existent record" }
      fail(:find, item)
    end
  end

  # Find all of the specified Upload records.
  #
  # @param [String, Upload, Array] items
  # @param [Hash]                  opt    Passed to #collect_records.
  #
  # @return [Array<Upload>]
  #
  def find_records(items, **opt)
    collect_records(items, **opt).first
  end

  # Create a new free-standing (un-persisted) Upload instance.
  #
  # @param [Hash, Upload] opt         Passed to Upload#initialize except for:
  #
  # @option opt [String] :file_path   File URI or path.
  # @option opt [Symbol] :meth        Calling method (for logging).
  #
  # @return [Upload]
  #
  # @see Upload#upload_file
  #
  def new_record(opt)
    __debug_args("UPLOAD #{__method__}", binding)
    opt  = opt.attributes if opt.is_a?(Upload)
    opt  = opt.deep_symbolize_keys
    meth = opt.delete(:meth) || __method__
    path = opt.delete(:file_path)
    Upload.new(opt).tap do |record|
      if (p = DEV_TITLE_PREFIX) && (title = record.emma_metadata[:dc_title])
        prefix = "#{p} - "
        prefix = nil if title.start_with?(prefix)
        # noinspection RubyYardParamTypeMatch
        record.modify_emma_data(dc_title: "#{prefix}#{title}") if prefix
      end
      # noinspection RubyYardParamTypeMatch
      record.upload_file(path, meth: meth) if path
    end
  end

  # ===========================================================================
  # :section: Records
  # ===========================================================================

  protected

  # Transform a mixture of Upload objects and record identifiers into a list of
  # Upload objects.
  #
  # @param [Array<Upload,String,Array>] items   @see Upload#collect_ids
  # @param [Boolean]                    force   See Usage Notes
  # @param [Hash]                       opt     Passed to Upload#get_records.
  #
  # @return [Array<(Array<Upload>,Array)>]      Upload records and failed ids.
  # @return [Array<(Array<Upload,String>,[])>]  If *force* is *true*.
  #
  # == Usage Notes
  # If *force* is true, the returned list of failed records will be empty but
  # the returned list of items may contain a mixture of Upload and String
  # elements.
  #
  def collect_records(*items, force: false, **opt)
    opt   = items.pop if items.last.is_a?(Hash) && opt.blank?
    items = items.flatten.compact

    # Searching for non-identifier criteria (e.g. { user: @user }).
    if opt.present? && items.blank?
      return Upload.get_records(**opt), []
    end

    # Searching for identifier criteria (possibly modified by other criteria).
    failed = []
    items =
      items.flat_map { |item|
        item.is_a?(Upload) ? item : Upload.collect_ids(item) if item.present?
      }.compact

    identifiers = items.reject { |item| item.is_a?(Upload) }
    if identifiers.present?
      found = {}
      Upload.get_records(*identifiers, **opt).each do |record|
        (id  = record.id.to_s).present?       and (found[id]  = record)
        (rid = record.repository_id).present? and (found[rid] = record)
      end
      items.map! { |item| !item.is_a?(Upload) && found[item] || item }
      items, failed = items.partition { |i| i.is_a?(Upload) } unless force
    end
    return items, failed
  end

  # ===========================================================================
  # :section: Storage
  # ===========================================================================

  protected

  # Associate a file with an Upload record and send the file to storage.
  #
  # @param [Upload, String] record
  # @param [String]         path      File URI or path.
  # @param [Symbol]         meth      Calling method (for logging).
  #
  # @raise [StandardError]            If *path* or *record* missing.
  #
  # @return [void]
  #
  # @see Upload#upload_file
  #
  def upload_file(record, path, meth: nil)
    __debug_args("UPLOAD #{__method__}", binding)
    meth ||= __method__
    raise "#{meth}: No upload file provided." if path.blank? # TODO: I18n
    record = get_record(record, meth: meth) unless record.is_a?(Upload)
    record.upload_file(path, meth: meth)
  end

  # Send the given file to storage
  #
  # @param [Upload, String] record
  # @param [Symbol]         meth      Calling method (for logging).
  #
  # @raise [StandardError]            If no :file_path was given or determined.
  #
  # @return [void]
  #
  # @see Upload#delete_file
  #
  def remove_file(record, meth: __method__)
    __debug_args("UPLOAD #{__method__}", binding)
    record = get_record(record, meth: meth) unless record.is_a?(Upload)
    record.delete_file
  end

  # ===========================================================================
  # :section: Database
  # ===========================================================================

  public

  # db_insert
  #
  # @param [Upload, Hash] data
  #
  # @return [Upload]
  #
  #--
  # noinspection RubyYardReturnMatch
  #++
  def db_insert(data)
    __debug_args("UPLOAD #{__method__}", binding)
    record = data.is_a?(Upload) ? data : new_record(data)
    record.save
    record
  end

  # db_update
  #
  # @param [Upload, String] record
  # @param [Hash]           data
  #
  # @return [Upload]
  #
  #--
  # noinspection RubyYardReturnMatch
  #++
  def db_update(record, data)
    __debug_args("UPLOAD #{__method__}", binding)
    record = get_record(record) unless record.is_a?(Upload)
    record.update(data)
    record
  end

  # db_delete
  #
  # @param [Upload, String] record
  #
  # @return [nil]                     Not destroyed.
  # @return [*]
  #
  def db_delete(record)
    __debug_args("UPLOAD #{__method__}", binding)
    record = get_record(record) unless record.is_a?(Upload)
    record.destroy
  end

  # ===========================================================================
  # :section: Database
  # ===========================================================================

  protected

  # Replace a list of failed database items with error entries.
  #
  # @param [Array<Upload,Hash,String>] items
  # @param [String]                    message
  # @param [Integer]                   position
  #
  # @return [Array<ErrorEntry>]
  #
  def db_failed_format!(items, message, position = 0)
    items.map! do |item|
      db_failed_format(item, message, (position += 1))
    end
  end

  # Create an error entry for a single failed database item.
  #
  # @param [Upload, Hash, String] item
  # @param [String]               message
  # @param [Integer]              position
  #
  # @return [ErrorEntry]
  #
  def db_failed_format(item, message, position)
    label = make_label(item, default: "Item #{position}") # TODO: I18n
    ErrorEntry.new(label, message)
  end

  # ===========================================================================
  # :section: Index ingest
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
  # @param [Hash]          atomic
  #
  # @raise [StandardError] @see IngestService::Request::Records#put_records
  #
  # @return [Array<(Array,Array,Array)>]  Succeeded records, failed item
  #                                         messages, and records to roll back.
  #
  def add_to_index(*items, atomic: true, **)
    __debug_args("UPLOAD #{__method__}", binding)
    succeeded, failed, rollback = update_in_index(*items, atomic: atomic)
    if rollback.present?
      # Any submissions that could not be added to the index will be removed
      # from the index.  The assumption here is that they failed because they
      # were missing information and need to be re-submitted anyway.
      removed, retained = upload_destroy(rollback, atomic: false, index: false)
      if removed.present?
        Log.info { "#{__method__}: rolled back: #{removed}" }
        removed_rids = removed.map(&:repository_id)
        rollback.reject! { |item| removed_rids.include?(item.repository_id) }
      end
      succeeded = [] if atomic
      failed += retained if retained.present?
      rollback.each(&:delete_file)
    end
    return succeeded, failed, rollback
  end

  # Add/modify the indicated items from the EMMA Unified Index.
  #
  # @param [Array<Upload>] items
  #
  # @raise [StandardError] @see IngestService::Request::Records#put_records
  #
  # @return [Array<(Array,Array,Array)>]  Succeeded records, failed item
  #                                         messages, and records to roll back.
  #
  def update_in_index(*items, **)
    __debug_args("UPLOAD #{__method__}", binding)
    succeeded = failed = rollback = []
    items = items.flatten.compact
    if items.present?
      result = ingest_api.put_records(*items)
      errors = result.errors
      if errors.blank?
        succeeded = items
      else
        rollback  = errors.transform_keys! { |n| items[n.to_i-1] }.keys.dup
        rids      = errors.transform_keys! { |item| repository_id(item) }.keys
        succeeded = items.reject { |item| rids.include?(item.repository_id) }
        failed    = errors.map { |rid, msg| ErrorEntry.new(rid, msg) }
      end
    end
    return succeeded, failed, rollback
  end

  # Remove the indicated items from the EMMA Unified Index.
  #
  # @param [Array<Upload, String>] items
  #
  # @raise [StandardError] @see IngestService::Request::Records#delete_records
  #
  # @return [Array<(Array,Array)>]    Succeeded items and failed item messages.
  #
  def remove_from_index(*items, **)
    __debug_args("UPLOAD #{__method__}", binding)
    succeeded = failed = []
    items = items.flatten.compact
    if items.present?
      result = ingest_api.delete_records(*items)
      errors = result.errors
      if errors.blank?
        succeeded = items
      else
        rids      = errors.keys
        succeeded = items.reject { |item| rids.include?(repository_id(item)) }
        failed    = errors.map { |rid, msg| ErrorEntry.new(rid, msg) }
      end
    end
    return succeeded, failed
  end

  # Override the normal methods if Unified Search update is disabled.

  if DISABLE_UPLOAD_INDEX_UPDATE

    %i[add_to_index update_in_index remove_from_index].each do |m|
      send(:define_method, m) { |*items, **| skip_index_ingest(m, *items) }
    end

    def skip_index_ingest(method, *items)
      __debug { "** SKIPPING ** UPLOAD #{method} | items = #{items.inspect}" }
      return items, []
    end

  end

  # ===========================================================================
  # :section: Bulk operations
  # ===========================================================================

  public

  # Bulk uploads.
  #
  # @param [Array<Hash,Upload>] entries
  # @param [Boolean]            atomic  If *false*, do not stop on failure.
  # @param [Boolean]            index   If *false*, do not update index.
  # @param [Hash]               opt     Passed to #bulk_upload_file.
  #
  # @return [Array<(Array,Array)>]  Succeeded records and failed item messages.
  #
  # @see #bulk_upload_file
  # @see #bulk_db_insert
  # @see #add_to_index
  #
  # Compare with:
  # @see #upload_create
  #
  #--
  # noinspection DuplicatedCode
  #++
  def bulk_upload_create(entries, atomic: true, index: true, **opt)
    __debug_args("UPLOAD #{__method__}", binding)

    # Translate Hash entries into Upload record instances and all related files
    # to storage.
    records, failed = bulk_upload_file(entries, **opt)
    return [], failed if atomic && failed.present? || records.blank?

    # Save the records to the database (and send associated files to storage).
    records, failed = bulk_db_insert(records, atomic: atomic)
    return [], failed if atomic && failed.present? || records.blank?

    # Include the new submissions in the index.
    return records, failed unless index && records.present?
    succeeded, rejected, _ = add_to_index(*records, atomic: atomic)
    return succeeded, (failed + rejected)
  end

  # Bulk modifications.
  #
  # @param [Array<Hash,Upload>] entries
  # @param [Boolean]            atomic  If *false*, do not stop on failure.
  # @param [Boolean]            index   If *false*, do not update index.
  # @param [Hash]               opt     Passed to #bulk_upload_file.
  #
  # @return [Array<(Array,Array)>]  Succeeded records and failed item messages.
  #
  # @see #bulk_upload_file
  # @see #bulk_db_update
  # @see #update_in_index
  #
  # Compare with:
  # @see #upload_update
  #
  #--
  # noinspection DuplicatedCode
  #++
  def bulk_upload_update(entries, atomic: true, index: true, **opt)
    __debug_args("UPLOAD #{__method__}", binding)

    # Translate hash entries into Upload record instances and ensure that all
    # related files are in storage.
    records, failed = bulk_upload_file(entries, **opt)
    return [], failed if atomic && failed.present? || records.blank?

    # Update records in the database.
    records, failed = bulk_db_update(records, atomic: atomic)
    return [], failed if atomic && failed.present? || records.blank?

    # Update the index with the modified submissions.
    return records, failed unless index && records.present?
    succeeded, rejected, _ = update_in_index(*records, atomic: atomic)
    return succeeded, (failed + rejected)
  end

  # Bulk removal.
  #
  # @param [Array<String,Integer>] id_specs
  # @param [Boolean]               atomic   If *false*, do not stop on failure.
  # @param [Boolean]               index    If *false*, do not update index.
  # @param [Boolean]               force    Force removal of index entries even
  #                                           if the related database entries
  #                                           do not exist.
  #
  # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
  #
  # @see #upload_destroy
  #
  # == Implementation Notes
  # For the time being, this does not use #bulk_db_delete because the speed
  # advantage of using a single SQL DELETE statement probably overwhelmed by
  # the need to fetch each record in order to call :delete_file on it.
  #
  def bulk_upload_destroy(id_specs, atomic: true, index: true, force: false)
    __debug_args("UPLOAD #{__method__}", binding)

    upload_destroy(id_specs, atomic: atomic, index: index, force: force)

    # # Translate entries into Upload record instances.
    # items, failed = collect_records(*items, force: force)
    # return [], failed if atomic && failed.present?
    #
    # # Remove the associated records from the database.
    # ids, failed = bulk_db_delete(ids, atomic: atomic)
    # return [], failed if atomic && failed.present? && !force
    #
    # # Remove the associated entries from the index.
    # return ids, failed unless index
    # remove_from_index(*ids, atomic: atomic)
  end

  # ===========================================================================
  # :section: Bulk operations - Storage
  # ===========================================================================

  protected

  # A fractional number of seconds to pause between iterations.
  #
  # @type [Float]
  #
  BULK_PAUSE = 0.01

  # Release the current thread to the scheduler.
  #
  # @param [Integer] counter          Iteration counter.
  # @param [Integer] frequency        E.g., '3' indicates every third iteration
  # @param [Float]   pause            Default: `#BULK_PAUSE`.
  #
  # @return [void]
  #
  def bulk_throttle(counter, frequency: 1, pause: BULK_PAUSE)
    return if counter.zero?
    return if (counter % frequency).nonzero?
    sleep(pause)
  end

  # Prepare entries for bulk insert/upsert to the database by ensuring that all
  # associated files have been uploaded and moved into storage.
  #
  # Failures of individual uploads are logged; the method will return with only
  # the successful uploads.
  #
  # @param [Array<Hash,Upload>] entries
  # @param [String]             base_url
  # @param [User, String]       user
  # @param [Integer]            limit     Only the first *limit* records.
  # @param [Hash]               opt       Optional added fields.
  #
  # @return [Array<(Array,Array)>]  Succeeded records and failed item messages.
  #
  # @see #new_record
  # @see Upload#promote_file
  #
  def bulk_upload_file(entries, base_url: nil, user: nil, limit: nil, **opt)
    opt[:file_path]  = Upload::BULK_PLACEHOLDER_FILE # TODO: remove when ready
    opt[:base_url]   = base_url || Upload::BULK_BASE_URL
    opt[:user_id]    = User.find_id(user || Upload::BULK_USER)
    opt[:importer] ||= Import::IaBulk # TODO: ?
    opt[:meth]     ||= __method__
    failed  = []
    counter = 0
    entries = Array.wrap(entries).reject(&:blank?)
    entries = entries.take(limit.to_i) if limit.to_i.positive?
    records =
      entries.map { |entry|
        # bulk_throttle(counter) # TODO: keep?
        counter += 1
        Log.info do
          msg = "#{__method__} [#{counter} of #{entries.size}]:"
          msg += " #{entry}" if entry.is_a?(Upload)
          msg
        end
        begin
          entry = new_record(entry.merge(opt)) unless entry.is_a?(Upload)
          entry.promote_file
          entry
        rescue => error
          failed << db_failed_format(entry, error.message, counter)
          Log.error { "#{__method__}: #{error.class}: #{error.message}" }
        end
      }.compact
    return records, failed
  end

  # ===========================================================================
  # :section: Bulk operations - Database
  # ===========================================================================

  public

  # Bulk create database records.
  #
  # @param [Array<Upload>] records
  # @param [Boolean]       atomic     If *false*, allow partial changes.
  #
  # @return [Array<(Array,Array)>]  Succeeded records and failed item messages.
  #
  # @see ActiveRecord::Persistence::ClassMethods#insert_all
  #
  def bulk_db_insert(records, atomic: true)
    succeeded, failed = bulk_db_operation(:insert_all, records, atomic: atomic)
    if succeeded.present?
      stored_idents = succeeded.map { |r| identifiers(r).presence || r }
      succeeded     = collect_records(*stored_idents).first
    end
    if failed.present?
      failed.each(&:delete_file)
      db_failed_format!(failed, 'Not added') # TODO: I18n
    end
    return succeeded, failed
  end

  # Bulk modify database records.
  #
  # @param [Array<Upload>] records
  # @param [Boolean]       atomic     If *false*, allow partial changes.
  #
  # @return [Array<(Array,Array)>]  Succeeded records and failed item messages.
  #
  # @see ActiveRecord::Persistence::ClassMethods#upsert_all
  #
  def bulk_db_update(records, atomic: true)
    succeeded, failed = bulk_db_operation(:upsert_all, records, atomic: atomic)
    if failed.present?
      # TODO: removal of newly-added files associated with failed records.
      db_failed_format!(failed, 'Not updated') # TODO: I18n
    end
    return succeeded, failed
  end

  # Bulk delete database records.
  #
  # @param [Array<String>] ids
  # @param [Boolean]       atomic     If *false*, allow partial changes.
  #
  # @return [Array<(Array,Array)>]  Succeeded records and failed item messages.
  #
  # @see ActiveRecord::Persistence::ClassMethods#delete
  #
  # @deprecated Use #upload_destroy instead.
  #
  # == Usage Notes
  # This method should be avoided in favor of #upload_destroy because use of
  # SQL DELETE on multiple record IDs does nothing for removing the associated
  # files in cloud storage.  Although code has been added to attempt to handle
  # this issue, it's untested.
  #
  def bulk_db_delete(ids, atomic: true)
    __debug_args("UPLOAD #{__method__}", binding)
    db_action = ->() {
      collect_records(*ids, force: false).first.each(&:delete_file)
      Upload.delete(ids)
    }
    success = false
    result =
      if atomic
        Upload.transaction do
          db_action.call.tap do |count|
            unless count == ids.size
              msg = [__method__]
              msg << 'atomic delete failed'
              msg << "#{count} of #{ids.size} deleted"
              raise ActiveRecord::Rollback, msg.join(': ')
            end
          end
        end
      else
        db_action.call
      end
    success = (result == ids.size)
  rescue => error
    Log.error { "#{__method__}: #{error.class}: #{error.message}" }
    raise error
  ensure
    # noinspection RubyScope
    if success
      return ids, []
    else
      return [], db_failed_format!(ids, 'Not removed') # TODO: I18n
    end
  end

  # ===========================================================================
  # :section: Bulk operations - Database
  # ===========================================================================

  protected

  # bulk_db_operation
  #
  # @param [Symbol]        operation  Upload class method.
  # @param [Array<Upload>] records
  #
  # @return [Array<(Array<Upload>,Array<Upload>)>]  Succeeded/failed records.
  #
  # == Implementation Notes
  # The 'failed' portion of the method return will always be empty if using
  # MySQL because ActiveRecord::Result for bulk operations does not contain
  # useful information.
  #
  def bulk_db_operation(operation, records, **)
    __debug_args((dbg = "UPLOAD #{__method__}"), binding)
    result = Upload.send(operation, records.map(&:attributes))
    if result.columns.blank? || (result.length == records.size)
      __debug_line(dbg) { 'QUALIFIED SUCCESS' }
      return records, []
    else
      updated = result.to_a.flat_map { |hash| identifiers(hash) }.compact
      __debug_line(dbg) { "UPDATED #{updated}" }
      records.partition { |record| updated.include?(identifier(record)) }
    end
  end

  # bulk_db_transaction
  #
  # @param [Symbol]        operation  Upload class method.
  # @param [Array<Upload>] records
  # @param [Boolean]       atomic     If *false*, allow partial changes.
  #
  # @return [Array<(Array<Upload>,Array<Upload>)>]  Succeeded/failed records.
  #
  # == Implementation Notes
  # Wrapping "INSERT INTO", etc. in a transaction seems to be problematic for
  # the MySQL instance deployed to AWS, so there may not be a use-case that
  # requires this method.
  #
  def bulk_db_transaction(operation, records, atomic: true)
    __debug_args((dbg = "UPLOAD #{__method__}"), binding)
    db_action = ->() { bulk_db_operation(operation, records) }
    return db_action.call unless atomic
    succeeded, failed = Upload.transaction(&db_action)
    return succeeded, failed if succeeded
    __debug_line(dbg) { 'TRANSACTION ROLLED BACK' }
    return [], records
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
    __debug_args("UPLOAD #{__method__}", binding)
    err = nil
    case problem
      when Symbol              then msg, err = UPLOAD_ERROR[problem]
      when Api::Error          then msg = problem.messages
      when Exception           then msg = problem.message
      when ActiveModel::Errors then msg = problem.full_messages
      else                          msg = problem
    end
    err ||= SubmitError
    intp  = msg.is_a?(String) && msg.include?('%') # Should interpolate value?
    msg ||= DEFAULT_ERROR_MESSAGE
    msg   = msg.join('; ') if msg.is_a?(Array)
    value = value.first    if value.is_a?(Array) && (value.size <= 1)
    case value
      when String
        msg = ERB::Util.h(msg) if (html = value.html_safe?)
        msg = intp ? (msg % value) : "#{msg}: #{value}"
        msg = html ? msg.html_safe : ERB::Util.h(msg)
      when Array
        # noinspection RubyNilAnalysis
        cnt = "(#{value.size})"
        msg = intp ? (msg % cnt) : "#{msg}: #{cnt}"
        msg = [msg] + value.map { |v| ErrorEntry[v] }
      else
        msg = [msg, ErrorEntry[value]]
    end
    raise err, msg
  end

  # Generate a response to a POST.
  #
  # @param [Symbol, Integer, Exception] status
  # @param [String, Exception]          message
  # @param [String]                     redirect
  # @param [Boolean]                    xhr       Override `request.xhr?`.
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
    __debug_args("UPLOAD #{__method__}", binding)
    status, message = [nil, status] if status.is_a?(Exception)
    status ||= :bad_request
    xhr      = request_xhr? if xhr.nil?
    if message.is_a?(Exception)
      ex     = message
      ex_msg = ex.respond_to?(:messages) ? ex.messages : Array.wrap(ex.message)
      if ex.respond_to?(:code)
        status = ex.code || status
      elsif ex.respond_to?(:response)
        status = ex.response.status || status
      end
      Log.error do
        msg = +"#{__method__}: #{status}: #{ex.class}:"
        if ex.is_a?(SubmitError) || ex.is_a?(Net::ProtocolError)
          msg << ' ' << ex_msg.join(', ')
        else
          msg << "\n" << ex.full_message(order: :top)
        end
      end
    else
      message = Array.wrap(message).map { |v| ErrorEntry[v] }
      ex_msg  = nil
      Log.info { [__method__, status, message.join(', ')].join(': ') }
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
      msg_max = FlashHelper::FLASH_MAX_ITEM_SIZE
      limit   = FlashHelper::FLASH_MAX_TOTAL_SIZE
      message = ex_msg || message
      message = message.map { |m| m.inspect.truncate(msg_max) }.presence
      message &&= safe_json_parse(message).to_json.truncate(limit)
      message ||= DEFAULT_ERROR_MESSAGE
      head status, 'X-Flash-Message': message
    end
  end

end

__loading_end(__FILE__)
