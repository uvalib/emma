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

    # Methods that are exposed for use in views.
    helper_method :title_prefix, :force_delete, :delete_truncate, :bulk_batch

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
    # @return [String]                  Record ID (:id).
    # @return [nil]                     No valid :id specified.
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
    # @return [String]                  Repository ID (:rid).
    # @return [nil]                     No valid :rid specified.
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
    # @return [String]
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

  # The Federated Ingest API cannot accept more than 1000 items; this puts a
  # hard upper-bound on batch sizes and the size of input values that certain
  # methods can accept.
  #
  # @type [Integer]
  #
  INGEST_MAX_SIZE = 1000

  # A string added to the start of each title created on a non-production
  # instance to help distinguish it from other index results.
  #
  # @type [String]
  #
  DEV_TITLE_PREFIX = 'RWL'

  # A string added to the start of each title.
  #
  # This should normally be *nil*.
  #
  # @type [String, nil]
  #
  # @see #title_prefix
  #
  TITLE_PREFIX = (DEV_TITLE_PREFIX unless application_deployed?)

  # Force deletions of Unified Index entries regardless of whether the item is
  # in the "uploads" table.
  #
  # When *false*, items that cannot be found in the "uploads" table are treated
  # as failures.
  #
  # When *true*, items identified by repository ID will be included in the
  # argument list to #remove_from_index unconditionally.
  #
  # @type [Boolean]
  #
  # @see #force_delete
  #
  FORCE_DELETE_DEFAULT = true

  # For the special case of deleting all records (effectively wiping the
  # database) this controls whether the next available ID should be set to 1.
  #
  # Otherwise, the next record after removing all records will have an 'id'
  # which is 1 greater than the last record prior to the deletion.
  #
  # When *false*, do not truncate the "uploads" table.
  #
  # When *true*, truncate the "uploads" table, resetting the initial ID to 1.
  #
  # @type [Boolean]
  #
  DELETE_TRUNCATE_DEFAULT = true

  # Handle bulk uploads in batches.
  #
  # When *false*, the complete set of items will be moved through each phase
  # together (all will be uploaded, then all will be added to the database,
  # then all will be added to the index).
  #
  # When *true*, the set of items is broken into batches, where each batch is
  # moved through each phase, and then the cycle is repeated with the next
  # batch, and so on until all items have been processed.
  #
  # @type [Boolean]
  #
  # @see #bulk_batch
  #
  BULK_BATCH_DEFAULT = true

  # Batches larger than this number are not permitted.
  #
  # @type [Integer]
  #
  MAX_BATCH_SIZE = INGEST_MAX_SIZE - 1

  # Break sets of submissions into chunks of this size.
  #
  # This is the value returned by #bulk_batch unless a different size was
  # explicitly given via the :batch URL parameter.
  #
  # @type [Integer]
  #
  # @see #set_bulk_batch
  #
  BULK_BATCH_SIZE = [ENV.fetch('BULK_BATCH_SIZE', 10).to_i, MAX_BATCH_SIZE].min

  # POST/PUT/PATCH parameters from the upload form that are not relevant to the
  # create/update of an Upload instance.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_UPLOAD_FORM_PARAMETERS = %i[limit field-group].sort.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameter relevant to the current operation.
  #
  # @return [Hash{Symbol=>String}]
  #
  def upload_params
    @upload_params || set_upload_params
  end

  # Set URL parameters relevant to the current operation.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [Hash{Symbol=>String}]
  #
  def set_upload_params(p = nil)
    prm = url_parameters(p)
    prm.except!(*IGNORED_UPLOAD_FORM_PARAMETERS)
    prm.deep_symbolize_keys!
    # noinspection RubyYardParamTypeMatch
    @upload_params = reject_blanks(prm)
  end

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
    prm  = set_upload_params(p)
    data = prm.delete(:upload) || {}
    file = data[:file]
    prm[:file_data] = file unless file.blank? || (file == '{}')
    prm[:base_url]  = request.base_url
    set_upload_params(prm)
  end

  # Extract POST parameters and data for bulk operations.
  #
  # @param [ActionController::Parameters, Hash] p   Default: `#url_parameters`.
  # @param [ActionDispatch::Request]            req Default: `#request`.
  #
  # @return [Array<Hash>]
  #
  def upload_bulk_post_parameters(p = nil, req = nil)
    prm = set_upload_params(p)
    src = prm[:src] || prm[:source]
    opt = src ? { src: src } : { data: (req || request) }
    Array.wrap(fetch_data(**opt)).map(&:symbolize_keys)
  end

  # A string added to the start of each title.
  #
  # @return [String]                  Value to prepend to title.
  # @return [FalseClass]              No prefix should be used.
  #
  # @see #set_title_prefix
  #
  def title_prefix
    set_title_prefix(upload_params[:prefix]) if @title_prefix.nil?
    @title_prefix
  end

  # Set the title prefix.
  #
  # @param [String, Boolean, nil] value
  #
  # @return [String]                  Value to prepend to title.
  # @return [FalseClass]              No prefix should be used.
  #
  # @see #TITLE_PREFIX
  #
  # == Usage Notes
  # The prefix cannot match any of #TRUE_VALUES or #FALSE_VALUES.
  #
  def set_title_prefix(value)
    @title_prefix =
      if false?(value)
        false
      elsif true?(value)
        TITLE_PREFIX
      else
        value.to_s.presence || TITLE_PREFIX
      end
  end

  # Force deletions of Unified Index entries regardless of whether the item is
  # in the "uploads" table.
  #
  # @return [Boolean]
  #
  # @see #FORCE_DELETE_DEFAULT
  # @see #set_force_delete
  #
  def force_delete
    set_force_delete(upload_params[:force]) if @force_delete.nil?
    @force_delete
  end

  # Set forced deletions of index entries.
  #
  # @param [String, Boolean, nil] value
  #
  # @return [Boolean]
  #
  # @see #parameter_setting
  # @see #FORCE_DELETE_DEFAULT
  #
  def set_force_delete(value)
    # noinspection RubyYardReturnMatch
    @force_delete = parameter_setting(value, FORCE_DELETE_DEFAULT)
  end

  # If all "uploads" records are removed, reset the next ID to 1.
  #
  # @return [Boolean]
  #
  # @see #DELETE_TRUNCATE_DEFAULT
  # @see #set_delete_truncate
  #
  def delete_truncate
    set_delete_truncate(upload_params[:truncate]) if @delete_truncate.nil?
    @delete_truncate
  end

  # Set truncation of "uploads" table when all records are removed.
  #
  # @param [String, Boolean, nil] value
  #
  # @return [Boolean]
  #
  # @see #parameter_setting
  # @see #DELETE_TRUNCATE_DEFAULT
  #
  def set_delete_truncate(value)
    # noinspection RubyYardReturnMatch
    @delete_truncate = parameter_setting(value, DELETE_TRUNCATE_DEFAULT)
  end

  # Handle bulk uploads in batches.
  #
  # If this is disabled, the method returns *false*; otherwise it returns the
  # batch size.
  #
  # @return [Integer]                 Bulk batch size.
  # @return [FalseClass]              Bulk operations should not be batched.
  #
  # @see #set_bulk_batch
  #
  def bulk_batch
    set_bulk_batch(upload_params[:batch]) if @bulk_batch.nil?
    @bulk_batch
  end

  # Set or disable bulk operation batching.
  #
  # @param [Integer, String, Boolean, nil] value
  #
  # @return [Integer]                 Bulk batch size.
  # @return [FalseClass]              Bulk operations should not be batched.
  #
  # @see #parameter_setting
  # @see #BULK_BATCH_DEFAULT
  # @see #BULK_BATCH_SIZE
  #
  #--
  # noinspection RubyYardParamTypeMatch, RubyYardReturnMatch
  #++
  def set_bulk_batch(value)
    @bulk_batch =
      if value.is_a?(TrueClass)
        BULK_BATCH_SIZE
      elsif value.is_a?(FalseClass)
        false
      elsif value.to_i.positive?
        [value.to_i, MAX_BATCH_SIZE].min
      elsif parameter_setting(value, BULK_BATCH_DEFAULT)
        BULK_BATCH_SIZE
      else
        false
      end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Pass a literal Boolean value or interpret a boolean-valued URL parameter
  # based on its stated default value.
  #
  # If *default* is *false* then *true* is returned only if *value* is "true".
  # If *default* is *true* then *false* is returned only if *value* is "false".
  #
  # @param [String, Boolean, nil]  value      Parameter value from `#params`.
  # @param [Boolean]               default    Default parameter value.
  #
  # @return [Boolean]
  #
  def parameter_setting(value, default)
    # noinspection RubyYardReturnMatch
    if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      value
    else
      default ? !false?(value) : true?(value)
    end
  end

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
  # @return [Array<(nil,Array)>]      No record; error message.
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
    return item, ['Entry not created'] unless item.is_a?(Upload) # TODO: I18n
    return item, item.errors           if item.errors.present?

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
  # @return [Array<(nil,Array)>]      No record; error message.
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
    return item, ["Entry #{id} not found"] unless item.is_a?(Upload) # TODO: I18n
    return item, item.errors               if item.errors.present?

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
  def upload_destroy(*items, atomic: true, index: true, force: false, **)
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
          bulk_throttle(counter)
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

  # The database ID for the item, or, failing that, the repository ID.
  #
  # @param [Upload, Hash, String] item
  #
  # @return [String]                  Record :id or :rid.
  # @return [nil]                     No identifier could be determined.
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
  # @param [Array<Upload,String,Array>] items
  # @param [Hash]                       opt     Passed to #collect_records.
  #
  # @return [Array<Upload>]
  #
  def find_records(*items, **opt)
    collect_records(*items, **opt).first
  end

  # Create a new free-standing (un-persisted) Upload instance.
  #
  # @param [Hash, Upload] opt         Passed to Upload#initialize.
  #
  # @return [Upload]
  #
  # @see Upload#upload_file
  #
  def new_record(opt)
    __debug_args("UPLOAD #{__method__}", binding)
    opt = opt.attributes if opt.is_a?(Upload)
    opt = opt.deep_symbolize_keys
    Upload.new(opt).tap { |record| add_title_prefix(record) if title_prefix }
  end

  # ===========================================================================
  # :section: Records
  # ===========================================================================

  protected

  # If a prefix was specified, apply it to the record's title.
  #
  # @param [Upload] record
  # @param [String] prefix
  #
  # @return [void]
  #
  def add_title_prefix(record, prefix: title_prefix)
    return if prefix.blank? || (title = record.emma_metadata[:dc_title]).nil?
    prefix = "#{prefix} - " unless prefix.match?(/[[:punct:]]\s*$/)
    prefix = "#{prefix} "   unless prefix.end_with?(' ')
    return if title.start_with?(prefix)
    # noinspection RubyYardParamTypeMatch
    record.modify_emma_data(dc_title: "#{prefix}#{title}")
  end

  # Transform a mixture of Upload objects and record identifiers into a list of
  # Upload objects.
  #
  # @param [Array<Upload,String,Array>] items   @see Upload#expand_ids
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
    return Upload.get_records(**opt), [] if opt.present? && items.blank?

    # Searching for identifier criteria (possibly modified by other criteria).
    failed = []
    items =
      items.flat_map { |item|
        item.is_a?(Upload) ? item : Upload.expand_ids(item) if item.present?
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
  # NOTE: Currently unused.
  #
  def upload_file(record, path, meth: nil)
    __debug_args("UPLOAD #{__method__}", binding)
    meth ||= __method__
    raise "#{meth}: No upload file provided." if path.blank? # TODO: I18n
    record = get_record(record, meth: meth) unless record.is_a?(Upload)
    record.upload_file(path, meth: meth) if record.present?
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
  # NOTE: Currently unused.
  #
  def remove_file(record, meth: __method__)
    __debug_args("UPLOAD #{__method__}", binding)
    record = get_record(record, meth: meth) unless record.is_a?(Upload)
    record.delete_file if record.present?
  end

  # ===========================================================================
  # :section: Database
  # ===========================================================================

  public

  # Add a single Upload record to the database.
  #
  # @param [Upload, Hash] data
  #
  # @return [Upload]                  The provided or created record.
  # @return [nil]                     If the record was not created or updated.
  #
  def db_insert(data)
    __debug_args("UPLOAD #{__method__}", binding)
    record = data.is_a?(Upload) ? data : new_record(data)
    record&.save
    # noinspection RubyYardReturnMatch
    record
  end

  # Modify a single existing Upload database record.
  #
  # @param [Upload, String] record
  # @param [Hash, nil]      data
  #
  # @return [Upload]                  The provided or located record.
  # @return [nil]                     If the record was not found or updated.
  #
  def db_update(record, data)
    __debug_args("UPLOAD #{__method__}", binding)
    record = get_record(record) unless record.is_a?(Upload)
    record&.update(data)
    # noinspection RubyYardReturnMatch
    record
  end

  # Remove a single existing Upload record from the database.
  #
  # @param [Upload, String] record
  #
  # @return [nil]                     If the record was not found or removed.
  # @return [*]
  #
  def db_delete(record)
    __debug_args("UPLOAD #{__method__}", binding)
    record = get_record(record) unless record.is_a?(Upload)
    record&.destroy
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
  # @param [Boolean]       atomic
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
      removed, kept = upload_destroy(*rollback, atomic: false, index: false)
      if removed.present?
        Log.info { "#{__method__}: rolled back: #{removed}" }
        removed_rids = removed.map(&:repository_id)
        rollback.reject! { |item| removed_rids.include?(item.repository_id) }
      end
      succeeded = [] if atomic
      failed += kept if kept.present?
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
    items = normalize_index_items(items, meth: __method__)
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
    items = normalize_index_items(items, meth: __method__)
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
  # :section: Index ingest
  # ===========================================================================

  public

  # Return a flatten array of items.
  #
  # @param [Array<Upload, String, Array>] items
  # @param [Symbol, nil]                  meth    The calling method.
  #
  # @raise [SubmitError] If the number of items is too large to be ingested.
  #
  # @return [Array]
  #
  def normalize_index_items(items, meth: nil)
    items = items.flatten.compact
    return items unless items.size > INGEST_MAX_SIZE
    error = [meth, 'item count', "#{item.size} > #{INGEST_MAX_SIZE}"]
    error = error.compact.join(': ')
    Log.Error(error)
    fail(error)
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
  # @param [Hash]               opt     Passed to #bulk_upload_file via
  #                                       #bulk_upload_operation.
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

    # Batch-execute this method unless it is being invoked within a batch.
    if opt[:bulk].blank?
      batch = bulk_batch || MAX_BATCH_SIZE
      opt.merge!(size: batch, atomic: atomic, index: index)
      return bulk_upload_operation(__method__, entries, **opt)
    end

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
  # @param [Hash]               opt     Passed to #bulk_upload_file via
  #                                       #bulk_upload_operation.
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

    # Batch-execute this method unless it is being invoked within a batch.
    if opt[:bulk].blank?
      batch = bulk_batch || MAX_BATCH_SIZE
      opt.merge!(size: batch, atomic: atomic, index: index)
      return bulk_upload_operation(__method__, entries, **opt)
    end

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
  # @param [Array<String,Integer,Hash,Upload>] id_specs
  # @param [Boolean] atomic           If *false*, do not stop on failure.
  # @param [Boolean] index            If *false*, do not update index.
  # @param [Hash]    opt              Passed to #upload_destroy via
  #                                     #bulk_upload_operation.
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
  def bulk_upload_destroy(id_specs, atomic: true, index: true, **opt)
    __debug_args("UPLOAD #{__method__}", binding)
    id_specs = Array.wrap(id_specs)
    force    = force_delete

    # Translate entries into Upload record instances if possible.
    items, failed = collect_records(*id_specs, force: force)
    return [], failed if atomic && failed.present? || items.blank?

    # Batching occurs unconditionally in order to ensure that the requested
    # items can be successfully removed from the index.
    batch = bulk_batch || MAX_BATCH_SIZE
    opt.merge!(size: batch, atomic: atomic, index: index, force: force)
    succeeded, failed = bulk_upload_operation(:upload_destroy, items, **opt)
    if delete_truncate && (id_specs == %w(*))
      if failed.blank?
        Upload.connection.truncate(Upload.table_name)
      else
        Log.warn('database not truncated due to the presence of errors')
      end
    end
    return succeeded, failed
  end

  # ===========================================================================
  # :section: Bulk operations
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

  # Process *entries* in batches by calling *op* on successive subsets.
  #
  # If *size* is *false* or negative, then *entries* is processed as a single
  # batch.
  #
  # If *size* is *true* or zero or missing, then *entries* is processed in
  # batches of the default #BULK_BATCH_SIZE.
  #
  # @param [Symbol]                            op
  # @param [Array<String,Integer,Hash,Upload>] entries
  # @param [Integer, Boolean]                  size     Def: #BULK_BATCH_SIZE.
  # @param [Hash]                              opt
  #
  # @return [Array<(Array,Array)>]  Succeeded records and failed item messages.
  #
  def bulk_upload_operation(op, entries, size: nil, **opt)
    __debug_args((dbg = "UPLOAD #{op}"), binding)
    opt[:bulk] ||= { total: entries.size }

    # Set batch size for this iteration.
    size = -1               if size.is_a?(FalseClass)
    size =  0               if size.is_a?(TrueClass)
    size = size.to_i
    size = entries.size     if size.negative?
    size = BULK_BATCH_SIZE  if size.zero?

    succeeded = []
    failed    = []
    counter   = 0
    entries.each_slice(size) do |batch|
      bulk_throttle(counter)
      min = size * counter
      max = (size * (counter += 1)) - 1
      opt[:bulk][:window] = { min: min, max: max }
      __debug_line(dbg) { "records #{min} to #{max}" }
      s, f = send(op, batch, **opt)
      succeeded += s
      failed    += f
    end
    __debug_line(dbg) { { succeeded: succeeded.size, failed: failed.size } }
    return succeeded, failed
  end

  # ===========================================================================
  # :section: Bulk operations - Storage
  # ===========================================================================

  protected

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
  # @param [Hash]               opt       Passed to #new_record except for:
  #
  # @option opt [Hash] :bulk              Info to support bulk upload
  #                                         reporting and error messages.
  #
  # @return [Array<(Array,Array)>]  Succeeded records and failed item messages.
  #
  # @see #new_record
  # @see Upload#promote_file
  #
  def bulk_upload_file(entries, base_url: nil, user: nil, limit: nil, **opt)
    opt[:base_url]   = base_url || Upload::BULK_BASE_URL
    opt[:user_id]    = User.find_id(user || Upload::BULK_USER)
    opt[:importer] ||= Import::IaBulk # TODO: ?

    # Honor :limit if given.
    limit   = limit.presence.to_i
    entries = Array.wrap(entries).reject(&:blank?)
    entries = entries.take(limit) if limit.positive?

    # Determine data properties for reporting purposes.
    properties  = opt.delete(:bulk)
    total_count = properties&.dig(:total)        || entries.size
    counter     = properties&.dig(:window, :min) || 0

    failed  = []
    records =
      entries.map { |entry|
        bulk_throttle(counter)
        counter += 1
        Log.info do
          msg = "#{__method__} [#{counter} of #{total_count}]:"
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

  # Break sets of records into chunks of this size.
  #
  # @type [Integer]
  #
  BULK_DB_BATCH_SIZE = ENV.fetch('BULK_DB_BATCH_SIZE', BULK_BATCH_SIZE).to_i

  # Bulk database operation.
  #
  # If the number of records exceeds *size* then it is broken up into batches
  # unless explicitly avoided.
  #
  # @param [Symbol]        op  Upload class method.
  # @param [Array<Upload>] records
  # @param [Boolean]       atomic     If *false*, allow partial changes.
  # @param [Integer]       size       Default: #BULK_DB_BATCH_SIZE
  #
  # @return [Array<(Array<Upload>,Array<Upload>)>]  Succeeded/failed records.
  #
  # @see #bulk_db_operation_batches
  # @see #bulk_db_operation_batch
  #
  # == Implementation Notes
  # For currently undiscovered reasons, the MySQL instance on AWS will be
  # overwhelmed if the "VALUE" portion of the "INSERT INTO" statement is very
  # large.  Breaking the data into bite-size chunks is currently the only
  # available work-around.
  #
  def bulk_db_operation(op, records, atomic: true, size: nil, **)
    __debug_args((dbg = "UPLOAD #{__method__}"), binding)
    size ||= BULK_DB_BATCH_SIZE
    succeeded, failed =
      if records.size <= size
        bulk_db_operation_batch(op, records)
      elsif !atomic
        bulk_db_operation_batches(op, records, size: size)
      else
        Upload.transaction do
          bulk_db_operation_batches(op, records, size: size)
        end
      end
    if succeeded.nil?
      __debug_line(dbg) { 'TRANSACTION ROLLED BACK' }
      return [], records
    else
      __debug_line(dbg) { { succeeded: succeeded.size, failed: failed.size } }
      return succeeded, failed
    end
  end

  # Invoke a database operation multiple times to process all of the given
  # records with manageably-sized SQL commands.
  #
  # @param [Symbol]        op         Upload class method.
  # @param [Array<Upload>] records
  # @param [Integer]       size
  #
  # @return [Array<(Array<Upload>,Array<Upload>)>]  Succeeded/failed records.
  #
  def bulk_db_operation_batches(op, records, size: BULK_DB_BATCH_SIZE)
    succeeded = []
    failed    = []
    counter   = 0
    records.each_slice(size) do |batch|
      bulk_throttle(counter)
      min  = size * counter
      max  = (size * (counter += 1)) - 1
      s, f = bulk_db_operation_batch(op, batch, from: min, to: max)
      succeeded += s
      failed    += f
    end
    return succeeded, failed
  end

  # Invoke a database operation.
  #
  # @param [Symbol]        op         Upload class method.
  # @param [Array<Upload>] records
  # @param [Integer]       from       For logging; default: 0.
  # @param [Integer]       to         For logging; default: tail of *records*.
  #
  # @return [Array<(Array<Upload>,Array<Upload>)>]  Succeeded/failed records.
  #
  # == Implementation Notes
  # The 'failed' portion of the method return will always be empty if using
  # MySQL because ActiveRecord::Result for bulk operations does not contain
  # useful information.
  #
  def bulk_db_operation_batch(op, records, from: nil, to: nil)
    from ||= 0
    to   ||= records.size - 1
    __debug(dbg = "UPLOAD #{op} | records #{from} to #{to}")
    result = Upload.send(op, records.map(&:attributes))
    if result.columns.blank? || (result.length == records.size)
      __debug_line(dbg) { 'QUALIFIED SUCCESS' }
      return records, []
    else
      updated = result.to_a.flat_map { |hash| identifiers(hash) }.compact
      __debug_line(dbg) { "UPDATED #{updated}" }
      records.partition { |record| updated.include?(identifier(record)) }
    end
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
      err  = err&.safe_constantize unless err.is_a?(Module)
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
      when ActiveModel::Errors then msg = problem.full_messages
      when Api::Error          then msg = problem.messages
      when Exception           then msg = problem.message
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
  # @param [String, Exception]          item
  # @param [String]                     redirect
  # @param [Boolean]                    xhr       Override `request.xhr?`.
  # @param [Symbol]                     meth      Calling method.
  #
  # @return [*]
  #
  # == Variations
  #
  # @overload post_response(status, item = nil, redirect: nil, xhr: nil)
  #   @param [Symbol, Integer]   status
  #   @param [String, Exception] item
  #
  # @overload post_response(except, redirect: nil, xhr: nil)
  #   @param [Exception] except
  #
  def post_response(status, item = nil, redirect: nil, xhr: nil, meth: nil)
    meth ||= calling_method
    __debug_args("UPLOAD #{meth} #{__method__}", binding)
    status, item = [nil, status] if status.is_a?(Exception)

    if item.is_a?(Exception)
      status ||= (item.code            if item.respond_to?(:code))
      status ||= (item.response.status if item.respond_to?(:response))
      message = Array.wrap(item)
    else
      message = Array.wrap(item).map { |v| ErrorEntry[v] }
    end
    status ||= :bad_request

    opt = { meth: meth, status: status }
    xhr = request_xhr? if xhr.nil?
    if xhr && !redirect
      head status, 'X-Flash-Message': flash_xhr(*message, **opt)
    else
      if %i[ok found].include?(status) || (200..399).include?(status)
        flash_success(*message, **opt)
      else
        flash_failure(*message, **opt)
      end
      if redirect
        redirect_to(redirect)
      else
        redirect_back(fallback_location: upload_index_path)
      end
    end
  end

end

__loading_end(__FILE__)
