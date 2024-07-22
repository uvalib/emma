# app/controllers/concerns/manifest_item_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/manifest_item" controller.
#
# @!method model_options
#   @return [ManifestItem::Options]
#
# @!method paginator
#   @return [ManifestItem::Paginator]
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module ManifestItemConcern

  extend ActiveSupport::Concern

  include Emma::Config
  include Emma::Common
  include Emma::Json

  include ImportConcern
  include SerializationConcern
  include ModelConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The manifest identified in URL parameters.
  #
  # @return [String, nil]
  #
  def manifest_id
    current_params unless defined?(@manifest_id)
    @manifest_id ||= @item&.manifest_id
  end

  # Extract POST parameters and data for bulk operations.
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  #
  # @return [Hash]
  #
  # @see ImportConcern#fetch_data
  #
  def manifest_item_bulk_post_params
    prm = current_post_params
    opt = prm.extract!(:src, :source, :data)
    opt[:src]  = opt.delete(:source) if opt.key?(:source)
    opt[:data] = request             if opt.blank?
    opt[:type] = prm.delete(:type)&.to_sym
    prm.merge!(data: fetch_data(**opt))
  end

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  # Get URL parameters relevant to the current operation.
  #
  # @return [Hash]
  #
  def current_get_params
    super do |prm|
      prm[:user] = @user if @user && !prm[:user] && !prm[:user_id] # TODO: should this be here?
      @manifest_id ||= extract_manifest_id(prm)
    end
  end

  # Extract POST parameters that are usable for creating/updating a Manifest
  # instance.
  #
  # @return [Hash]
  #
  def current_post_params
    super do |prm|
      @manifest_id ||= extract_manifest_id(prm)
    end
  end

  # Locate and filter ManifestItem records.
  #
  # @param [Array<String,Array>] items
  # @param [Array<Symbol>]       filters
  # @param [Hash]                opt
  #
  # @return [Paginator::Result]
  #
  def find_or_match_records(*items, filters: [], **opt)
    opt.except!(:group, :groups) # TODO: groups
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The related Manifest identified in URL parameters.
  #
  # @param [Hash] prm
  #
  # @return [Integer, nil]
  #
  def extract_manifest_id(prm)
    item = prm[:manifest_id] || prm[:manifest]
    item = item.id if item.is_a?(Manifest)
    item.presence
  end

  # ===========================================================================
  # :section: ImportConcern overrides
  # ===========================================================================

  public

  # Interpret data as JSON.
  #
  # @param [String, ActionDispatch::Request, nil] data
  #
  # @return [Array<Hash>, nil]
  #
  def from_json(data)
    super&.map! { |item| import_transform!(item) }
  end

  # Interpret data as CSV.
  #
  # @param [String, ActionDispatch::Request, nil] data
  #
  # @return [Array<Hash>, nil]
  #
  def from_csv(data)
    super&.map! { |item| import_transform!(item) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Transform import data into ManifestItem field values.
  #
  # @param [Hash] item
  #
  # @return [Hash]
  #
  def import_transform!(item)
    normalize_import_name!(item)
    attr = ManifestItem.normalize_attributes(item, revalidate: true)
    item.replace(attr.except(:attr_opt))
  end

  # Transform ManifestItem field values for export.
  #
  # @param [Hash] item
  #
  # @return [Hash]
  #
  def export_transform!(item)
    normalize_export_name!(item)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Restoration of ManifestItem fields on import.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  IMPORT_FIELD = {
    manifest_item_id:  :id,
    manifest_item_row: :row,
    manifest:          :manifest_id,
  }.freeze

  # Transform received data to allow some flexibility in the naming of import
  # columns by mapping into the expected field names.
  #
  # @param [Hash] item
  #
  # @return [Hash]
  #
  def normalize_import_name!(item)
    item.transform_keys! { |k| IMPORT_FIELD[k] || k }
  end

  # Transformation of ManifestItem fields on export.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  EXPORT_FIELD = {
    id:       :manifest_item_id,
    row:      :manifest_item_row,
    manifest: :manifest_id,
  }.freeze

  # Transform potentially ambiguous field names into ones that are not likely
  # to clash if exported data is intermingled with fields from other systems
  # and then re-imported.
  #
  # @param [Hash] item
  #
  # @return [Hash]
  #
  def normalize_export_name!(item)
    item.transform_keys! { |k| EXPORT_FIELD[k] || k }
  end

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  # Return with the specified model record.
  #
  # @param [any, nil] item      String, Integer, Hash, Model; def: #identifier.
  # @param [Hash]     opt       Passed to Record::Identification#find_record.
  #
  # @raise [Record::StatementInvalid] If :id not given.
  # @raise [Record::NotFound]         If *item* was not found.
  #
  # @return [ManifestItem, nil] A fresh record unless *item* is a #model_class.
  #
  # @yield [record] Raise an exception if the record is not acceptable.
  # @yieldparam [ManifestItem] record
  # @yieldreturn [void]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def find_record(item = nil, **opt, &blk)
    return super if blk
    authorized_session
    super do |record|
      authorized_self_or_org_member(record)
    end
  end

  # Start a new ManifestItem.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Hash]      opt            Added field values.
  #
  # @option opt [Boolean] force       If *true* allow setting of :id.
  #
  # @return [ManifestItem]            An un-persisted ManifestItem instance.
  #
  # @yield [attr] Adjust attributes and/or raise an exception.
  # @yieldparam [Hash] attr           Supplied attributes for the new record.
  # @yieldreturn [void]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def new_record(prm = nil, **opt, &blk)
    return super if blk
    authorized_session
    super
  end

  # Add a new ManifestItem record to the database.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Boolean]   fatal          If *false*, use #save not #save!.
  # @param [Hash]      opt            Added field values.
  #
  # @option opt [Boolean] force       If *true* allow setting of :id.
  #
  # @return [ManifestItem]            The new ManifestItem record.
  #
  # @yield [attr] Adjust attributes and/or raise an exception.
  # @yieldparam [Hash] attr           Supplied attributes for the new record.
  # @yieldreturn [void]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def create_record(prm = nil, fatal: true, **opt, &blk)
    return super if blk
    authorized_session
    super do |attr|
      attr[:backup] ||= {}
      attr[:row]    ||= 1 + all_manifest_items(**attr)&.last&.row.to_i
    end
  end

  # Retrieve the indicated ManifestItem record for the '/edit' model form.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Hash]     opt             Passed to #find_record.
  #
  # @raise [Record::SubmitError]      Record could not be found.
  #
  # @return [ManifestItem, nil] A fresh instance unless *item* is ManifestItem.
  #
  # @yield [record] Raise an exception if the record is not acceptable.
  # @yieldparam [ManifestItem] record
  # @yieldreturn [void] Block not called if *record* is *nil*.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def edit_record(item = nil, **opt, &blk)
    return item  if item.is_a?(ManifestItem)
    return super if blk
    super do |record|
      authorized_self_or_org_member(record)
    end
  end

  # Update the indicated ManifestItem record.
  #
  # @param [any, nil] item            Def.: record for ModelConcern#identifier.
  # @param [Boolean]  fatal           If *false* use #update not #update!.
  # @param [Hash]     opt             Field values except #UPDATE_STATUS_OPT
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [ManifestItem, nil]       The updated ManifestItem record.
  #
  # @yield [record, attr] Raise an exception if the record is not acceptable.
  # @yieldparam [ManifestItem] record
  # @yieldparam [Hash]         attr   New field(s) to be assigned to *record*.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def update_record(item = nil, fatal: true, **opt, &blk)
    return super if blk
    keep_date = updated_at = old_values = nil
    super { |record, attr|
      opt        = attr.extract!(*ManifestItem::UPDATE_STATUS_OPT)
      keep_date  = !opt[:overwrite] unless opt[:overwrite].nil?
      new_fields = keep_date.nil? && attr.except(*NON_EDIT_KEYS).keys.presence
      old_values = new_fields && record.fields.slice(*new_fields)
      updated_at = record[:updated_at]
    }&.tap { |record|
      if keep_date.nil?
        keep_date = old_values&.all? { |k, v| record[k].to_s == v.to_s }
      end
      record.set_field_direct(:updated_at, updated_at) if keep_date
    }
  end

  # Retrieve the indicated ManifestItem record(s) for the '/delete' page.
  #
  # @param [any, nil] items           To #search_records
  # @param [Hash]     opt             Default: `#current_params`
  #
  # @raise [RangeError]               If :page is not valid.
  #
  # @return [Paginator::Result]
  #
  # @yield [items, opt] Raise an exception unless the *items* are acceptable.
  # @yieldparam [Array] items         Identifiers of items to be deleted.
  # @yieldparam [Hash]  options       Options to #search_records.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  def delete_records(items = nil, **opt, &blk)
    return super if blk
    authorized_session
    super do |_items, options|
      options.except!(:force, :emergency, :truncate)
    end
  end

  # Remove the indicated ManifestItem record(s).
  #
  # @param [any, nil] items
  # @param [Boolean]  fatal           If *false* do not #raise_failure.
  # @param [Hash]     opt             Default: `#current_params`
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Destroyed ManifestItem records.
  #
  # @yield [record] Called for each record before deleting.
  # @yieldparam [ManifestItem] record
  # @yieldreturn [String,nil]         Error message if *record* unacceptable.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def destroy_records(items = nil, fatal: true, **opt, &blk)
    return super if blk
    authorized_session
    super do |record|
      unless authorized_self_or_org_member(record, fatal: false)
        "no authorization to remove #{record}"
      end
    end
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  RECORD_KEYS   = ManifestItem::RECORD_COLUMNS.excluding(:repository).freeze
  NON_DATA_KEYS = ManifestItem::NON_DATA_COLS.excluding(:field_error).freeze
  NON_EDIT_KEYS = ManifestItem::NON_EDIT_COLS

  # Set :editing state (along with any other fields if they are provided).
  #
  # @param [ManifestItem, nil] item   Def.: record for ModelConcern#identifier.
  # @param [Boolean, nil]      fatal  Passed to database method if present.
  # @param [Symbol, nil]       meth   Caller (for diagnostics).
  # @param [Hash]              attr   Field values.
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [ManifestItem]
  # @return [nil]                     Only if *fatal* == *false*.
  #
  def start_editing(item = nil, fatal: nil, meth: nil, **attr)
    meth ||= __method__
    opt    = { fatal: fatal }.compact
    attr.merge!(editing: true)
    if (rec = edit_record(item, fatal: false))
      if rec.editing
        Log.warn { "#{meth}: #{rec.id}: already editing #{rec.inspect}" }
      end
      if attr[:backup].present?
        Log.debug { "#{meth}: #{rec.id}: already backed up" } if rec.backup
      elsif attr.key?(:backup)
        Log.debug { "#{meth}: #{rec.id}: clearing backup" }
        attr[:backup] = nil
      elsif !rec.backup && (backup = rec.get_backup).present?
        Log.debug { "#{meth}: #{rec.id}: making backup" }
        attr[:backup] = backup
      end
      attr[:attr_opt] = { overwrite: false }
      update_record(rec, **attr, **opt)
    else
      # noinspection RubyMismatchedReturnType
      create_record(attr, **opt)
    end
  end

  # Update with provided fields (if any) and clear :editing state.
  #
  # @param [ManifestItem, nil] item   Def.: record for ModelConcern#identifier.
  # @param [Symbol, nil]       meth   Caller (for diagnostics).
  # @param [Hash]              attr   Field values.
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [Hash]
  #
  # @see file:controllers/manifest-edit.js *parseFinishEditResponse*
  #
  def finish_editing(item = nil, meth: nil, **attr)
    meth ||= __method__
    item   = edit_record(item)
    Log.warn { "#{meth}: not editing: #{item.inspect}" } unless item.editing
    editing_update(item, **attr)
  end

  # Update with provided fields (if any) and clear :editing state.
  #
  # @param [ManifestItem, nil] item   Def.: record for ModelConcern#identifier.
  # @param [Hash]              attr   Field values.
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [Hash]
  #
  # @see file:javascripts/controllers/manifest-edit.js *postRowUpdate*
  #
  def editing_update(item = nil, **attr)
    rec   = edit_record(item)
    file  = attr.key?(:file_status)  || attr.key?(:file_data)
    data  = attr.key?(:data_status)  || attr.except(*RECORD_KEYS).present?
    ready = attr.key?(:ready_status) || file || data
    opt   = { file: file, data: data, ready: ready, revalidate: true }
    attr[:attr_opt] = attr[:attr_opt]&.reverse_merge(opt) || opt
    check = attr[:attr_opt].values_at(:file, :data, :ready).any?

    update_record(rec, **attr, editing: false)

    result = { items: { rec.id => rec.fields.except(*NON_DATA_KEYS) } }
    result.merge!(pending:  rec.manifest.pending_items_hash) if check
    result.merge!(problems: rec.errors.to_hash)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # Upload a file to the AWS S3 Shrine :cache and update record :file_data with
  # the response.
  #
  # The Shrine response is augmented with an :emma_data entry containing the
  # record fields -- including :id since this may be the first "edit" of the
  # grid item and thus the first opportunity for the client to learn what
  # database entry is associated with that item.
  #
  # @param [ManifestItem, nil] item         Def.: ModelConcern#identifier.
  # @param [Boolean]           update_time  If *false* update :file_data only.
  # @param [Hash, nil]         env          Def.: `request.env`.
  # @param [Symbol, nil]       meth         Caller (for diagnostics).
  # @param [Hash]              opt          Field values.
  #
  # @return [Array<(Integer, Hash{String=>any,nil}, Array<String>)>]
  #
  # @note If update_time is *false* the associated record must already exist.
  #
  def upload_file(item = nil, update_time: true, env: nil, meth: nil, **opt)
    meth ||= __method__
    env  ||= request.env
    if update_time
      record = start_editing(item, meth: meth, **opt)
    else
      record = edit_record(item, **opt.slice(:id))
    end
    status, headers, body = record.upload_file(env: env)
    if status == 200
      body.map! do |entry|
        file_data = json_parse(entry)
        emma_data = file_data&.delete(:emma_data)&.presence
        if !file_data
          # NOTE: Should not happen normally if status is 200...
          Log.debug { "#{meth}: unexpected response item #{entry.inspect}" }
          entry  = config_term(:manifest_item, :uploader, :error)
          status = 400
        elsif !update_time
          record.set_field_direct(:file_data, file_data)
        else
          update_record(record, file_data: file_data, editing: false)
          emma_data &&= record.fields.merge(emma_data).except!(*NON_DATA_KEYS)
          entry = file_data.merge!(emma_data: emma_data).to_json if emma_data
        end
        entry
      end
    end
    return status, headers, body
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  protected

  # A relation for all items of the indicated Manifest ordered by row.
  #
  # @param [String, nil] m_id   Manifest ID.
  # @param [Hash]        opt
  #
  # @option opt [String]       :manifest_id
  # @option opt [String, Hash] :manifest
  #
  # @return [ActiveRecord::Relation<ManifestItem>]
  #
  def all_manifest_items(m_id = nil, **opt)
    m_id ||= opt[:manifest_id] || opt[:manifest]
    m_id = m_id[:id]      if m_id.is_a?(Hash)
    raise_failure(:no_id) if m_id.blank?
    ManifestItem.where(manifest_id: m_id).in_row_order
  end

  # ===========================================================================
  # :section: Workflow - Bulk
  # ===========================================================================

  public

  # bulk_new_manifest_items
  #
  # @return [any, nil]
  #
  def bulk_new_manifest_items
    prm = current_params
    if prm.slice(:src, :source, :manifest).present?
      post make_path(bulk_create_manifest_item_path, **prm)
    else
      # TODO: bulk_new_manifest_items
    end
  end

  # bulk_create_manifest_items
  #
  # @param [Array<Symbol>] returning  Returned result columns.
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array<Hash>]             Created items.
  #
  def bulk_create_manifest_items(returning: ManifestItem.field_names)
    result = ManifestItem.insert_all(bulk_item_data, returning: returning)
    # noinspection RubyMismatchedArgumentType
    bulk_returning(result)
  rescue ActiveRecord::ActiveRecordError => error
    raise_failure(error)
  end

  # bulk_edit_manifest_items
  #
  # @return [any, nil]
  #
  def bulk_edit_manifest_items
    prm = current_params
    if prm.slice(:src, :source, :manifest).present?
      put make_path(bulk_update_manifest_item_path, **prm)
    else
      # TODO: bulk_edit_manifest_items
    end
  end

  # bulk_update_manifest_items
  #
  # @param [Array<Symbol>] returning  Returned result columns.
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array<Hash>]             Modified items.
  #
  def bulk_update_manifest_items(returning: ManifestItem.field_names)
    result = ManifestItem.upsert_all(bulk_item_data, returning: returning)
    # noinspection RubyMismatchedArgumentType
    bulk_returning(result)
  rescue ActiveRecord::ActiveRecordError => error
    raise_failure(error)
  end

  # bulk_delete_manifest_items
  #
  # @return [any, nil]
  #
  def bulk_delete_manifest_items
    prm = current_params
    if prm.slice(:src, :source, :manifest).present?
      delete make_path(bulk_destroy_manifest_item_path, **prm)
    else
      # TODO: bulk_delete_manifest_items
    end
  end

  # bulk_destroy_manifest_items
  #
  # This marks items for deletion unless `params[:commit]` is true.
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array<Integer>]          Affected items.
  #
  def bulk_destroy_manifest_items
    prm = current_params
    ids = Array.wrap(prm.values_at(:ids, :id).compact.first)
    raise_failure(:destroy, :no_ids) if ids.blank?
    if prm[:commit]
      ManifestItem.delete_by(id: ids)
    else
      ManifestItem.where(id: ids).update_all(deleting: true)
    end
    ids
  end

  # bulk_fields_manifest_items
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array<Hash>]             Modified items.
  #
  def bulk_fields_manifest_items
    current_post_params[:data].map { |id, updates|
      id = id.to_s.to_i
      ManifestItem.find(id).set_fields_direct(updates) rescue next
      { id: id }
    }.compact
=begin # TODO: why doesn't this work with JSON columns?
    items  = manifest_item_post_params[:data] or return
    items  = items.map { |id, updates| { id: id.to_s.to_i, **updates } }
    result = ManifestItem.upsert_all(items)
    bulk_returning(result)
=end
  rescue ActiveRecord::ActiveRecordError => error
    raise_failure(error)
  end

  # ===========================================================================
  # :section: Workflow - Bulk
  # ===========================================================================

  protected

  # Data for one or more manifest items from parameters.
  #
  # @return [Array<Hash>]
  #
  def bulk_item_data
    prm   = manifest_item_bulk_post_params
    items = prm[:data]
    raise_failure(:not_array, items.inspect) unless items.is_a?(Array)
    raise_failure(:no_data)                  unless items.present?
    row   = prm[:row].to_i
    delta = prm[:delta].to_i
    items.map do |item|
      raise_failure(:not_hash, items.inspect)     unless items.is_a?(Array)
      item[:manifest_id] = item.delete(:manifest) if item.key?(:manifest)
      if item[:manifest_id].blank?
        item[:manifest_id] = manifest_id
      elsif item[:manifest_id] != manifest_id
        raise_failure(:invalid_id, item.inspect)
      end
      row   = (item[:row]   ||= row)
      delta = (item[:delta] ||= delta + 1)
      item  = ManifestItem.normalize_attributes(item, revalidate: true)
      item.except(:attr_opt)
    end
  end

  # Transform a :returning result into an array of data hashes.
  #
  # @param [ActiveRecord::Result] result
  #
  # @return [Array<Hash>]
  #
  def bulk_returning(result)
    types = result.column_types
    result.rows.map do |row|
      result.columns.map.with_index { |col, idx|
        k = col.to_sym
        v = types[col]&.deserialize(row[idx]) || row[idx]
        [k, v]
      }.to_h
    end
  end

  # ===========================================================================
  # :section: ResponseConcern overrides
  # ===========================================================================

  public

  def default_fallback_location = manifest_item_index_path

  # Generate a response to a POST.
  #
  # @param [Symbol, Integer, Exception, nil] status
  # @param [any, nil]                        item
  # @param [Hash]                            opt
  #
  # @return [void]
  #
  def post_response(status, item = nil, **opt)
    opt[:meth]     ||= calling_method
    opt[:fallback] ||=
      if manifest_id
        manifest_item_index_path(manifest: manifest_id)
      else
        manifest_index_path
      end
    super
  end

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  protected

  # Create an Options instance from the current parameters.
  #
  # @return [ManifestItem::Options]
  #
  def get_model_options
    ManifestItem::Options.new(request_parameters)
  end

  # ===========================================================================
  # :section: PaginationConcern overrides
  # ===========================================================================

  public

  # Create a Paginator for the current controller action.
  #
  # @param [Class<Paginator>] paginator  Paginator class.
  # @param [Hash]             opt        Passed to super.
  #
  # @return [ManifestItem::Paginator]
  #
  def pagination_setup(paginator: ManifestItem::Paginator, **opt)
    # noinspection RubyMismatchedReturnType
    super
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # @private
  # @type [Symbol, String]
  RESPONSE_OUTER = :items

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [any, nil] list            Default: `paginator.page_items`
  # @param [Hash]     opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = nil, **opt)
    opt.reverse_merge!(wrap: RESPONSE_OUTER)
    super
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [any, nil] item            Model, Hash
  # @param [Hash]     opt
  #
  # @return [Hash]
  #
  def show_values(item = @item, **opt)
    if item.is_a?(Model) || item.is_a?(Hash)
      # noinspection RailsParamDefResolve
      item = item.try(:fields) || item.dup
      file = item.delete(:file_data)
      item[:file_data] = safe_json_parse(file) if file
    end
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
