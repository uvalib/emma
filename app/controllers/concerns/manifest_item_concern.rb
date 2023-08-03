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
  # @return [Hash{Symbol=>*}]
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
  # @return [Hash{Symbol=>*}]
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
  # @return [Hash{Symbol=>*}]
  #
  def current_post_params
    super do |prm|
      @manifest_id ||= extract_manifest_id(prm)
    end
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
  # @return [Array<Hash{Symbol=>*}>]
  # @return [nil]
  #
  def from_json(data)
    super&.map! { |item| import_transform!(item) }
  end

  # Interpret data as CSV.
  #
  # @param [String, ActionDispatch::Request, nil] data
  #
  # @return [Array<Hash{Symbol=>*}>]
  # @return [nil]
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
  # @param [Hash{Symbol=>*}] item
  #
  # @return [Hash{Symbol=>*}]
  #
  def import_transform!(item)
    normalize_import_name!(item)
    item.replace(ManifestItem.normalize_attributes(item).except!(:attr_opt))
  end

  # Transform ManifestItem field values for export.
  #
  # @param [Hash{Symbol=>*}] item
  #
  # @return [Hash{Symbol=>*}]
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
  # @param [Hash{Symbol=>*}] item
  #
  # @return [Hash{Symbol=>*}]
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
  # @param [Hash{Symbol=>*}] item
  #
  # @return [Hash{Symbol=>*}]
  #
  def normalize_export_name!(item)
    item.transform_keys! { |k| EXPORT_FIELD[k] || k }
  end

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  def find_or_match_records(*items, filters: [], **opt)
    opt[:user] = current_user unless administrator?
    filters = [*filters, :filter_by_user!] if opt[:user] || opt[:user_id]
    super
  end

  # Create and persist a new ManifestItem.
  #
  # @param [Hash, nil] attr           Default: `#current_params`.
  # @param [Hash]      opt            Passed to super.
  #
  # @return [ManifestItem]            A new ManifestItem instance.
  #
  def create_record(attr = nil, **opt)
    attr          ||= current_params
    attr[:backup] ||= {}
    attr[:row]    ||= 1 + all_manifest_items(**attr)&.last&.row.to_i
    # noinspection RubyMismatchedReturnType
    super
  end

  # Retrieve the indicated ManifestItem for the '/edit' model form.
  #
  # @param [ManifestItem, nil] item   Def.: record for ModelConcern#identifier.
  # @param [Hash, nil]         prm
  # @param [Hash]              opt
  #
  # @raise [Record::SubmitError]      Record could not be found.
  #
  # @return [ManifestItem, nil]       An existing persisted ManifestItem.
  #
  def edit_record(item = nil, prm = nil, **opt)
    # noinspection RubyMismatchedReturnType
    item.is_a?(ManifestItem) ? item : super
  end

  # Update the indicated ManifestItem.
  #
  # @param [ManifestItem, nil] item   Def.: record for ModelConcern#identifier.
  # @param [Hash]              attr    Field values except #UPDATE_STATUS_OPTS.
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [ManifestItem, nil]       The updated ManifestItem instance.
  #
  def update_record(item = nil, no_raise: false, **attr)
    keep_date = updated_at = old_values = nil
    # noinspection RubyMismatchedReturnType
    super { |record, opt|
      return unless record
      attr_opt   = opt.extract!(*ManifestItem::UPDATE_STATUS_OPTS)
      keep_date  = !attr_opt[:overwrite] unless attr_opt[:overwrite].nil?
      new_fields = keep_date.nil? && attr.except(*NON_EDIT_KEYS).keys.presence
      old_values = new_fields && record.fields.slice(*new_fields)
      updated_at = record[:updated_at]
    }.tap { |record|
      return unless record
      if keep_date.nil?
        keep_date = old_values&.all? { |k, v| record[k].to_s == v.to_s }
      end
      record.set_field_direct(:updated_at, updated_at) if keep_date
    }
  end

  # Retrieve the indicated record(s) for the '/delete' page.
  #
  # @param [String, Model, Array, nil] items
  # @param [Hash, nil]                 prm    Default: `#current_params`
  #
  # @raise [RangeError]               If :page is not valid.
  #
  # @return [Hash{Symbol=>*}]         From Record::Searchable#search_records.
  #
  def delete_records(items = nil, prm = nil, **)
    items, prm = model_request_params(items, prm)
    prm.except!(:force, :emergency, :truncate)
    super
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
  # @param [Symbol, nil]       meth   Caller (for diagnostics).
  # @param [Hash]              attr   Field values.
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [ManifestItem] Or *nil* if opt[:no_raise] == *true*.
  #
  def start_editing(item = nil, meth: nil, **attr)
    meth ||= __method__
    attr.merge!(editing: true)
    if (rec = edit_record(item, no_raise: true))
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
      update_record(rec, **attr)
    else
      # noinspection RubyMismatchedReturnType
      create_record(attr)
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
    attr[:attr_opt] = { file: file, data: data, ready: ready }
    update_record(rec, **attr, editing: false)
    {
      items:    { rec.id => rec.fields.except(*NON_DATA_KEYS) },
      pending:  (rec.manifest.pending_items_hash if file || data || ready),
      problems: rec.errors.to_hash,
    }
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
  # @return [Array<(Integer, Hash{String=>*}, Array<String>)>]
  #
  # @note If update_time is *false* the associated record must already exist.
  #
  def upload_file(item = nil, update_time: true, env: nil, meth: nil, **opt)
    meth ||= __method__
    env  ||= request.env
    if update_time
      record = start_editing(item, meth: meth, **opt)
    else
      record = edit_record(item, { id: opt[:id] })
    end
    status, headers, body = record.upload_file(env: env)
    if status == 200
      body.map! do |entry|
        file_data = json_parse(entry)
        emma_data = file_data&.delete(:emma_data)&.presence
        if !file_data
          # NOTE: Should not happen normally if status is 200...
          Log.debug { "#{meth}: unexpected response item #{entry.inspect}" }
          entry  = 'unknown uploader error' # TODO: I18n
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
  # @param [String, nil] manifest_id
  # @param [Hash]        opt
  #
  # @option opt [String]       :manifest_id
  # @option opt [String, Hash] :manifest
  #
  # @return [ActiveRecord::Relation<ManifestItem>]
  #
  def all_manifest_items(manifest_id = nil, **opt)
    manifest_id ||= opt[:manifest_id] || opt[:manifest]
    manifest_id = manifest_id[:id] if manifest_id.is_a?(Hash)
    raise_failure('No :manifest_id was provided') if manifest_id.blank?
    ManifestItem.where(manifest_id: manifest_id).in_row_order
  end

  # ===========================================================================
  # :section: Workflow - Bulk
  # ===========================================================================

  public

  # bulk_new_manifest_items
  #
  # @return [*]
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
    bulk_returning(result)
  rescue ActiveRecord::ActiveRecordError => error
    raise_failure(error)
  end

  # bulk_edit_manifest_items
  #
  # @return [*]
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
    bulk_returning(result)
  rescue ActiveRecord::ActiveRecordError => error
    raise_failure(error)
  end

  # bulk_delete_manifest_items
  #
  # @return [*]
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
    raise_failure(:destroy, 'no record identifiers') if ids.blank?
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
    raise_failure("not an Array: #{items.inspect}") unless items.is_a?(Array)
    raise_failure('no item data')                   unless items.present?
    row   = prm[:row].to_i
    delta = prm[:delta].to_i
    items.map do |item|
      raise_failure("not a Hash: #{item.inspect}") unless item.is_a?(Hash)
      item[:manifest_id] = item.delete(:manifest) if item.key?(:manifest)
      if item[:manifest_id].blank?
        item[:manifest_id] = manifest_id
      elsif item[:manifest_id] != manifest_id
        raise_failure("invalid manifest_id for #{item.inspect}")
      end
      row   = (item[:row]   ||= row)
      delta = (item[:delta] ||= delta + 1)
      ManifestItem.normalize_attributes(item).except!(:attr_opt)
    end
  end

  # Transform a :returning result into an array of data hashes.
  #
  # @param [ActiveRecord::Result] result
  #
  # @return [Array<Hash{Symbol=>*}>]
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
  # @param [*]                               item
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
  RESPONSE_OUTER = :items

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [*]    list
  # @param [Hash] opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list, **opt)
    super(list, wrap: RESPONSE_OUTER, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Model, Hash, *] item
  # @param [Hash]           opt
  #
  # @return [Hash{Symbol=>*}]
  #
  def show_values(item = @item, **opt)
    if item.is_a?(Model) || item.is_a?(Hash)
      # noinspection RailsParamDefResolve
      item = item.try(:fields) || item.dup
      file = item.delete(:file_data)
      item[:file_data] = safe_json_parse(file) if file
    end
    super(item, **opt)
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
