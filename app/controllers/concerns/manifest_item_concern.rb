# app/controllers/concerns/manifest_item_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/manifest_item" controller.
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

  include ParamsHelper
  include FlashHelper
  include HttpHelper

  include ImportConcern
  include OptionsConcern
  include PaginationConcern
  include ResponseConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters associated with item/row identification.
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_PARAMS = ManifestItem::Options::IDENTIFIER_PARAMS

  # URL parameters associated with POST data.
  #
  # @type [Array<Symbol>]
  #
  DATA_PARAMS = ManifestItem::Options::DATA_PARAMS

  # The manifest item identified in URL parameters.
  #
  # @return [Integer, nil]
  #
  def manifest_item_id
    manifest_item_params unless defined?(@manifest_item_id)
    @manifest_item_id
  end

  # The manifest identified in URL parameters.
  #
  # @return [String, nil]
  #
  def manifest_id
    manifest_item_params unless defined?(@manifest_id)
    @manifest_id ||= @item&.manifest_id
  end

  # URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>*}]
  #
  def manifest_item_params
    @manifest_item_params ||=
      request.get? ? manifest_item_get_params : manifest_item_post_params
  end

  # Get URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>*}]
  #
  def manifest_item_get_params
    model_options.get_model_params.tap do |prm|
      prm[:user] = @user if @user && !prm[:user] && !prm[:user_id] # TODO: should this be here?
      @manifest_item_id ||= extract_identifier(prm)
      @manifest_id      ||= prm[:manifest_id] || prm[:manifest]
    end
  end

  # Extract POST parameters that are usable for creating/updating a
  # ManifestItem instance.
  #
  # @return [Hash{Symbol=>*}]
  #
  def manifest_item_post_params
    model_options.model_post_params.tap do |prm|
      extract_hash!(prm, *DATA_PARAMS).each_pair do |_, v|
        next unless (v &&= safe_json_parse(v)).is_a?(Hash)
        prm[:id]            = v[:id]
        prm[:manifest_id] ||= v[:manifest_id] || v[:manifest]
      end
      @manifest_item_id ||= extract_identifier(prm)
      @manifest_id      ||= prm[:manifest_id] || prm[:manifest]
    end
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
    prm = manifest_item_post_params
    opt = extract_hash!(prm, :src, :source, :data)
    opt[:src]  = opt.delete(:source) if opt.key?(:source)
    opt[:data] = request             if opt.blank?
    opt[:type] = prm.delete(:type)&.to_sym
    prm.merge!(data: fetch_data(**opt))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # extract_identifier
  #
  # @param [Hash] prm
  #
  # @return [Integer, nil]
  #
  def extract_identifier(prm)
    id, sel = prm.values_at(*IDENTIFIER_PARAMS).map(&:presence)
    [sel, id].compact.find { |v| digits_only?(v) }&.to_i
  end

  # ===========================================================================
  # :section: ImportConcern overrides
  # ===========================================================================

  protected

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

  public

  # Transform import data into ManifestItem field values.
  #
  # @param [Hash{Symbol=>*}] item
  #
  # @return [Hash{Symbol=>*}]
  #
  def import_transform!(item)
    normalize_import_name!(item)
    transform_identifiers!(item)
    reject_unknown!(item)
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

  # Retain only data which is usable to update a ManifestItem.
  #
  # @param [Hash{Symbol=>*}] item
  #
  # @return [Hash{Symbol=>*}]
  #
  def reject_unknown!(item)
    item.slice!(*ManifestItem.field_names)
    item
  end

  # Normalized column names which are allowed as a source of :dc_identifier
  # values.
  #
  # @type [Hash{Symbol=>Class}]
  #
  ID_COLUMN = {
    isbn: Isbn,
    issn: Issn,
    doi:  Doi,
    oclc: Oclc,
    lccn: Lccn,
  }.freeze

  # Transform standard identifier values into non-ambiguous form (if necessary)
  # and allow columns named for a specific identifier type to be accepted.
  #
  # @param [Hash{Symbol=>*}] item
  #
  # @return [Hash{Symbol=>*}]
  #
  def transform_identifiers!(item)
    id_columns = extract_hash!(item, *ID_COLUMN.keys)
    return item unless id_columns.present? || item.key?(:dc_identifier)
    ids = Array.wrap(item[:dc_identifier])
    ids.map! { |v| PublicationIdentifier.cast(v, invalid: true) }
    ids += id_columns.map { |k, v| ID_COLUMN[k].cast(v, invalid: true) }
    ids.map!(&:to_s).compact_blank!.uniq!
    item.merge!(dc_identifier: ids)
  end

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
    item.transform_keys! { |k| k.to_s.gsub(/\s+/, '_').underscore.to_sym }
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
  # :section:
  # ===========================================================================

  public

  # Parameters used by ManifestItem#search_records.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_RECORDS_PARAMS = ManifestItem::SEARCH_RECORDS_OPTIONS

  # ManifestItem#search_records parameters that specify a distinct search query
  #
  # @type [Array<Symbol>]
  #
  SEARCH_ONLY_PARAMS = (SEARCH_RECORDS_PARAMS - %i[offset limit]).freeze

  # Parameters used by #find_by_match_records or passed on to
  # ManifestItem#search_records.
  #
  # @type [Array<Symbol>]
  #
  FIND_OR_MATCH_PARAMS = (
    SEARCH_RECORDS_PARAMS + %i[group state user user_id]
  ).freeze

  # Locate and filter ManifestItem records.
  #
  # @param [Array<String,Integer,Array>] items  Default: `#manifest_item_id`.
  # @param [Hash] opt                 Passed to ManifestItem#search_records;
  #                                     default: `#manifest_item_params` if no
  #                                     *items* are given.
  #
  # @raise [Record::SubmitError]      If :page is not valid.
  #
  # @return [Hash{Symbol=>*}]
  #
  def find_or_match_manifest_items(*items, **opt)
    items = items.flatten.compact
    items << manifest_item_id if items.blank? && manifest_item_id.present?

    # If neither items nor field queries were given, use request parameters.
    if items.blank? && opt.except(*SEARCH_ONLY_PARAMS).blank?
      opt = manifest_item_params.merge(opt) unless opt[:groups] == :only
    end
    opt[:limit] ||= paginator.page_size
    opt[:page]  ||= paginator.page_number

    # Disallow experimental database WHERE predicates unless privileged.
    opt.slice!(*FIND_OR_MATCH_PARAMS) unless current_user&.administrator?

    # Select records for the current user unless a different user has been
    # specified (or all records if specified as '*', 'all', or 'false').
    user = opt.delete(:user)
    user = opt.delete(:user_id) || user || @user
    user = user.to_s.strip.downcase if user.is_a?(String) || user.is_a?(Symbol)
    # noinspection RubyMismatchedArgumentType
    user = User.find_record(user)   unless %w(* 0 all false).include?(user)
    opt[:user_id] = user.id         if user.is_a?(User) && user.id.present?

    # Limit records to those in the given state (or records with an empty state
    # field if specified as 'nil', 'empty', or 'missing').
    # noinspection RubyUnusedLocalVariable
    if (state = opt.delete(:state).to_s.strip.downcase).present?
=begin # TODO: ManifestItem state?
      if %w(empty false missing nil none null).include?(state)
        opt[:state] = nil
      else
        opt[:state] = state
        #opt[:edit_state] ||= state
      end
=end
    end

    # Limit by workflow status group.
    # noinspection RubyUnusedLocalVariable
    group = opt.delete(:group)
=begin # TODO: ManifestItem groups?
    group = group.split(/\s*,\s*/) if group.is_a?(String)
    group = Array.wrap(group).compact_blank
    if group.present?
      group.map!(&:downcase).map!(&:to_sym)
      if group.include?(:all)
        %i[state edit_state].each { |k| opt.delete(k) }
      else
        states =
          group.flat_map { |g|
            Record::Steppable::STATE_GROUP.dig(g, :states)
          }.compact.map(&:to_s)
        #%i[state edit_state].each do |k|
        %i[state].each do |k|
          opt[k] = (Array.wrap(opt[k]) + states).uniq
          opt.delete(k) if opt[k].empty?
        end
      end
    end
=end
    opt.delete(:groups)

    ManifestItem.search_records(*items, **opt)

  rescue RangeError => error

    # Re-cast as a SubmitError so that ManifestItemController#index redirects
    # to the main index page instead of the root page.
    raise Record::SubmitError.new(error)

  end

  # Return with the specified ManifestItem record.
  #
  # @param [*]    item                  Default: #manifest_item_id.
  # @param [Hash] opt                   To ManifestItem#find_record.
  #
  # @option opt [Boolean] :no_raise     If *true*, return *nil* if not found.
  #
  # @raise [Record::NotFound]           If *item* was not found.
  # @raise [Record::StatementInvalid]   If :id/:sid not given.
  #
  # @return [ManifestItem]
  #
  def get_manifest_item(item = nil, **opt)
    case item
      when ManifestItem, Hash then id = item[:id]
      when Integer, String    then id = item
      else                         id = opt.delete(:id)
    end
    # noinspection RubyMismatchedReturnType
    ManifestItem.find_record((id || manifest_item_id), **opt)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # Create a new un-persisted ManifestItem, using *item* as a template if
  # provided, for the '/new' model form.
  #
  # @param [Hash] opt                       Field values.
  #
  # @return [ManifestItem]                  Un-persisted ManifestItem instance.
  #
  def new_manifest_item(**opt)
    __debug_items("MANIFEST ITEM WF #{__method__}", binding)
    ManifestItem.new(opt)
  end

  # Create and persist a new ManifestItem.
  #
  # @param [Hash] opt                       Field values.
  #
  # @raise [Record::SubmitError]            Invalid workflow transition.
  # @raise [ActiveRecord::RecordInvalid]    Update failed due to validations.
  # @raise [ActiveRecord::RecordNotSaved]   Update halted due to callbacks.
  #
  # @return [ManifestItem]                  A new ManifestItem instance.
  #
  def create_manifest_item(**opt)
    __debug_items("MANIFEST ITEM WF #{__method__}", binding)
    opt[:backup] ||= {}
    opt[:row]    ||= 1 + all_manifest_items(**opt)&.last&.row.to_i
    us_opt = extract_hash!(opt, *ManifestItem::UPDATE_STATUS_OPTS)
    ManifestItem.update_status!(opt, **us_opt, **opt)
    ManifestItem.create!(opt)
  end

  # Retrieve the indicated ManifestItem for the '/edit' model form.
  #
  # @param [ManifestItem, nil] item   Default: record for #manifest_item_id.
  # @param [Hash]              opt    Passed to #get_manifest_item.
  #
  # @raise [Record::SubmitError]      Record could not be found.
  #
  # @return [ManifestItem]            An existing persisted ManifestItem.
  #
  def edit_manifest_item(item = nil, **opt)
    #__debug_items("MANIFEST ITEM WF #{__method__}", binding)
    # noinspection RubyMismatchedReturnType
    item.is_a?(ManifestItem) ? item : get_manifest_item(**opt)
  end

  # Update the indicated ManifestItem.
  #
  # @param [ManifestItem, nil] item   Default: record for #manifest_item_id.
  # @param [Hash]              opt    Field values except #UPDATE_STATUS_OPTS.
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [ManifestItem]            The updated ManifestItem instance.
  #
  def update_manifest_item(item = nil, **opt)
    __debug_items("MANIFEST ITEM WF #{__method__}", binding)
    edit_manifest_item(item).tap do |record|
      us_opt = extract_hash!(opt, *ManifestItem::UPDATE_STATUS_OPTS)
      record.update_status!(**us_opt, **opt)
      record.update!(opt)
    end
  end

  # Retrieve the indicated ManifestItem(s) for the '/delete' page.
  #
  # @param [String, ManifestItem, Array, nil] items
  # @param [Hash]                             opt   Search parameters.
  #
  # @raise [RangeError]               If :page is not valid.
  #
  # @return [Hash{Symbol=>*}]         From Record::Searchable#search_records.
  #
  def delete_manifest_item(items = nil, **opt)
    __debug_items("MANIFEST ITEM WF #{__method__}", binding)
    id_opt  = extract_hash!(opt, :ids, :id)
    items ||= id_opt.compact.values.first || manifest_item_id
    opt.except!(:force, :emergency, :truncate)
    ManifestItem.search_records(*items, **opt)
  end

  # Remove the indicated ManifestItem(s).
  #
  # @param [String, ManifestItem, Array, nil] items
  # @param [Hash]                             opt   Search parameters.
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Destroyed ManifestItems.
  #
  def destroy_manifest_item(items = nil, **opt)
    __debug_items("MANIFEST ITEM WF #{__method__}", binding)
    opt.reverse_merge!(model_options.all)
    ids   = extract_hash!(opt, :ids, :id).compact.values.first
    items = [*items, *ids].map! { |row| row.try(:id) || row }
    succeeded, failed = [[], []]
    ManifestItem.where(id: items).each do |record|
      if record.destroy
        succeeded << record.id
      else
        failed << record.id
      end
    end
    failure(:destroy, failed.uniq) if failed.present?
    succeeded
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  RECORD_KEYS   = ManifestItem::RECORD_COLUMNS.excluding(:repository).freeze
  NON_DATA_KEYS = ManifestItem::NON_DATA_COLS

  # Set :editing state (along with any other fields if they are provided).
  #
  # @param [ManifestItem, nil] item   Default: record for #manifest_item_id.
  # @param [Hash]              opt    Field values.
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [ManifestItem] Or *nil* if opt[:no_raise] == *true*.
  #
  def start_editing(item = nil, **opt)
    opt.merge!(editing: true)
    meth = opt.delete(:meth) || __method__
    if (rec = edit_manifest_item(item, no_raise: true))
      warn  = ("already editing #{rec.inspect}" if rec.editing)
      debug = nil
      if opt[:backup].present?
        debug = 'already backed up' if rec.backup
      elsif opt.key?(:backup)
        debug = 'clearing backup'
        opt[:backup] = nil
      elsif !rec.backup && (backup = rec.get_backup).present?
        debug = 'making backup'
        opt[:backup] = backup
      end
      Log.warn  { "#{meth}: #{rec.id}: #{warn}"  } if warn
      Log.debug { "#{meth}: #{rec.id}: #{debug}" } if debug
      us_opt = { overwrite: false }
      update_manifest_item(rec, **us_opt, **opt)
    else
      create_manifest_item(**opt)
    end
  end

  # Update with provided fields (if any) and clear :editing state.
  #
  # @param [ManifestItem, nil] item   Default: record for #manifest_item_id.
  # @param [Hash]              opt    Field values.
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [Hash]
  #
  # @see file:controllers/manifest-edit.js *parseFinishEditResponse*
  #
  def finish_editing(item = nil, **opt)
    meth = opt.delete(:meth) || __method__
    item = edit_manifest_item(item)
    Log.warn { "#{meth}: not editing: #{item.inspect}" } unless item.editing
    editing_update(item, **opt)
  end

  # Update with provided fields (if any) and clear :editing state.
  #
  # @param [ManifestItem, nil] item   Default: record for #manifest_item_id.
  # @param [Hash]              opt    Field values.
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [Hash]
  #
  # @see file:javascripts/controllers/manifest-edit.js *postRowUpdate*
  #
  def editing_update(item = nil, expect_editing: false, **opt)
    rec    = edit_manifest_item(item)
    file   = opt.key?(:file_status)  || opt.key?(:file_data)
    data   = opt.key?(:data_status)  || opt.except(*RECORD_KEYS).present?
    ready  = opt.key?(:ready_status) || file || data
    us_opt = { file: file, data: data, ready: ready, overwrite: true }
    update_manifest_item(rec, **us_opt, **opt, editing: false)
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
  # @param [ManifestItem, nil] item   Default: record for #manifest_item_id.
  # @param [Hash]              opt    Field values.
  #
  # @return [Array<(Integer, Hash{String=>*}, Array<String>)>]
  #
  def upload_file(item = nil, **opt)
    meth   = opt.delete(:meth) || __method__
    env    = opt.delete(:env)  || request
    env    = env.env if env.is_a?(ActionDispatch::Request)
    record = start_editing(item, **opt, meth: meth)
    record.upload_file(env: env).tap do |_, _, body|
      body.map! do |entry|
        if (file_data = safe_json_parse(entry)).is_a?(Hash)
          # noinspection RubyNilAnalysis
          emma_data = file_data.delete(:emma_data) || {}
          update_manifest_item(record, file_data: file_data, editing: false)
          emma_data = record.fields.merge(emma_data).except!(*NON_DATA_KEYS)
          file_data.merge!(emma_data: emma_data).to_json
        else
          Log.debug { "#{meth}: unexpected response item #{entry.inspect}" }
          entry
        end
      end
    end
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
    failure('No :manifest_id was provided') if manifest_id.blank?
    ManifestItem.where(manifest_id: manifest_id).order('row, delta')
  end

  # ===========================================================================
  # :section: Workflow - Bulk
  # ===========================================================================

  public

  # bulk_new_manifest_items
  #
  # @return [Any]
  #
  def bulk_new_manifest_items
    prm = manifest_item_params
    if prm.slice(:src, :source, :manifest).present?
      post make_path(bulk_create_manifest_item_path, **prm)
    else
      # TODO: bulk_new_manifest_items
    end
  end

  # bulk_create_manifest_items
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array<Hash>]             Created items.
  #
  def bulk_create_manifest_items
    items = bulk_item_data(validate: true)
    res   = ManifestItem.insert_all(items, returning: ManifestItem.field_names)
    bulk_returning(res)
  rescue ActiveRecord::ActiveRecordError => error
    failure(error)
  end

  # bulk_edit_manifest_items
  #
  # @return [Any]
  #
  def bulk_edit_manifest_items
    prm = manifest_item_params
    if prm.slice(:src, :source, :manifest).present?
      put make_path(bulk_update_manifest_item_path, **prm)
    else
      # TODO: bulk_edit_manifest_items
    end
  end

  # bulk_update_manifest_items
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array<Hash>]             Modified items.
  #
  def bulk_update_manifest_items
    items = bulk_item_data(validate: true)
    res   = ManifestItem.upsert_all(items, returning: ManifestItem.field_names)
    bulk_returning(res)
  rescue ActiveRecord::ActiveRecordError => error
    failure(error)
  end

  # bulk_delete_manifest_items
  #
  # @return [Any]
  #
  def bulk_delete_manifest_items
    prm = manifest_item_params
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
    prm = manifest_item_params
    ids = Array.wrap(prm.values_at(:ids, :id).compact.first)
    failure(:destroy, 'no record identifiers') if ids.blank?
    if prm[:commit]
      ManifestItem.delete_by(id: ids)
    else
      ManifestItem.where(id: ids).update_all(deleting: true)
    end
    ids
  end

  # ===========================================================================
  # :section: Workflow - Bulk
  # ===========================================================================

  protected

  # Data for one or more manifest items from parameters.
  #
  # @param [Boolean] validate     If *true*, update status fields.
  #
  # @return [Array<Hash>]
  #
  def bulk_item_data(validate: false)
    items = manifest_item_bulk_post_params[:data]
    failure("not an Array: #{items.inspect}") unless items.is_a?(Array)
    failure('no item data')                   unless items.present?
    items.map do |item|
      failure("not a Hash: #{item.inspect}") unless item.is_a?(Hash)
      item[:manifest_id] = item.delete(:manifest) if item.key?(:manifest)
      if item[:manifest_id].blank?
        item[:manifest_id] = manifest_id
      elsif item[:manifest_id] != manifest_id
        failure("invalid manifest_id for #{item.inspect}")
      end
      ManifestItem.update_status!(item) if validate
      # noinspection RubyMismatchedArgumentType
      ManifestItem.attribute_options(item)
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
    opt[:tag]      ||= "MANIFEST ITEM #{opt[:meth]}"
    opt[:fallback] ||=
      if manifest_id
        manifest_item_index_path(manifest: manifest_id)
      else
        manifest_index_path
      end
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Raise an exception.
  #
  # @param [Symbol, String, Array<String>, ExecReport, Exception, nil] problem
  # @param [Any, nil]                                                  value
  #
  # @raise [Record::SubmitError]
  # @raise [ExecError]
  #
  # @see ExceptionHelper#failure
  #
  def failure(problem, value = nil)
    ExceptionHelper.failure(problem, value, model: :manifest_item)
  end

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  # Create a @model_options instance from the current parameters.
  #
  # @return [ManifestItem::Options]
  #
  def set_model_options
    # noinspection RubyMismatchedVariableType, RubyMismatchedReturnType
    @model_options = ManifestItem::Options.new(request_parameters)
  end

  # ===========================================================================
  # :section: PaginationConcern overrides
  # ===========================================================================

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
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
