# app/controllers/concerns/upload_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/upload" controller.
#
# @!method model_options
#   @return [Upload::Options]
#
# @!method paginator
#   @return [Upload::Paginator]
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module UploadConcern

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Json

  include ParamsHelper
  include FlashHelper

  include ImportConcern
  include IngestConcern
  include SerializationConcern
  include ModelConcern

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  public

  MIME_REGISTRATION =
    FileNaming.format_classes.values.each(&:register_mime_types)

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
      @db_id ||=
        prm.values_at(:submission_id, :id).find { digits_only?(_1) }&.to_i
    end
  end

  # Extract POST parameters that are usable for creating/updating a Manifest
  # instance.
  #
  # @return [Hash]
  #
  def current_post_params
    super do |prm|
      prm[:base_url] = request.base_url
      @db_id ||=
        prm.values_at(:submission_id, :id).find { digits_only?(_1) }&.to_i
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Extract POST parameters and data for bulk operations.
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  #
  # @return [Array<Hash>]
  #
  # @see ImportConcern#fetch_data
  #
  def upload_bulk_post_params
    prm = current_post_params
    opt = prm.extract!(prm, :src, :source, :data)
    opt[:src]  = opt.delete(:source) if opt.key?(:source)
    opt[:data] = request             if opt.blank?
    opt[:type] = prm.delete(:type)&.to_sym
    fetch_data(**opt) || []
  end

  # workflow_parameters
  #
  # @return [Hash]
  #
  def workflow_parameters
    result = { id: db_id, user_id: @user&.id }
    result.compact!
    result.merge!(current_post_params)
    result.except!(:selected)
  end

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  def search_records_keys
    model_class.const_get(:SEARCH_RECORDS_OPT)
  end

  def find_or_match_keys
    super(:edit_state, :edit_user)
  end

  # Locate and filter Upload records.
  #
  # @param [Array<String,Array>] items    Default: `UploadConcern#identifier`.
  # @param [Array<Symbol>]       filters  Filter methods to limit/modify params
  # @param [Hash]                opt      Passed to Upload#search_records;
  #                                         default: `#current_params` if no
  #                                         *items* are given.
  #
  # @raise [UploadWorkflow::SubmitError]  If :page is not valid.
  #
  # @return [Paginator::Result]
  #
  def find_or_match_records(*items, filters: [], **opt)
    filters = [*filters, :filter_by_state!, :filter_by_group!]
    super
  end

  # Select records for the current user unless a different user has been
  # specified (or all records if specified as '*', 'all', or 'false').
  #
  # @param [Hash]  opt                May be modified.
  #
  def filter_by_user!(opt)
    super
    user = opt[:id].presence
    opt[:edit_user] = user if user
  end

  # Limit records to those in the given state (or records with an empty state
  # field if specified as 'nil', 'empty', or 'missing').
  #
  # @param [Hash]  opt                May be modified.
  #
  # @return [Hash, nil]               *opt* if changed.
  #
  def filter_by_state!(opt)
    super or return
    state = opt[:state].presence
    opt[:edit_state] ||= state if state
    opt
  end

  # Limit by workflow status group.
  #
  # @param [Hash]                 opt     May be modified.
  # @param [Symbol]               key     Group URL parameter.
  # @param [Symbol|Array<Symbol>] state   State parameter(s).
  #
  # @return [Hash, nil]                   *opt* if changed.
  #
  def filter_by_group!(opt, key: :group, state: %i[state edit_state])
    super
  end

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  # Start a new EMMA submission Upload instance.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Hash]      opt            Added field values.
  #
  # @return [Upload]                  An un-persisted Upload record.
  #
  # @see UploadWorkflow::Single::Create::States#on_creating_entry
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def new_record(prm = nil, **opt, &blk)
    not_implemented 'CANNOT HANDLE prm' if prm # TODO: ???
    not_implemented 'CANNOT HANDLE blk' if blk # TODO: ???
    return super if blk
    authorized_session
    opt.reverse_merge!(rec: db_id || :unset)
    wf_single(event: :create, **opt)
  end

  # Generate a new EMMA submission by adding a new Upload record to the
  # database and updating the EMMA Unified Index.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Boolean]   fatal          If *false*, use #save not #save!.
  # @param [Hash]      opt            Added field values.
  #
  # @return [Upload]                  The new Upload record.
  #
  # @see UploadWorkflow::Single::Create::States#on_submitting_entry
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def create_record(prm = nil, fatal: true, **opt, &blk)
    not_implemented 'CANNOT HANDLE prm' if prm # TODO: ???
    not_implemented 'CANNOT HANDLE blk' if blk # TODO: ???
    return super if blk
    authorized_session
    wf_single(event: :submit, **opt)
  end

  # Start editing an existing EMMA submission Upload record.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Hash]     opt             Passed to #wf_single.
  #
  # @raise [Record::StatementInvalid] If :id not given.
  # @raise [Record::NotFound]         If *item* was not found.
  #
  # @return [Upload, nil]             A fresh record unless *item* is an Upload
  #
  # @see UploadWorkflow::Single::Edit::States#on_editing_entry
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def edit_record(item = nil, **opt, &blk)
    not_implemented 'CANNOT HANDLE item' if item # TODO: ???
    not_implemented 'CANNOT HANDLE blk'  if blk  # TODO: ???
    return super if blk
    authorize_item(item)
    wf_single(event: :edit, **opt)
  end

  # Update an EMMA submission by persisting changes to an existing Upload
  # record and updating the EMMA Unified Index.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Boolean]  fatal           If *false* use #update not #update!.
  # @param [Hash]     opt             Passed to #wf_single.
  #
  # @raise [Record::NotFound]               If the record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Model record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Model record update halted.
  #
  # @return [Upload, nil]             The updated Upload record.
  #
  # @see UploadWorkflow::Single::Edit::States#on_modifying_entry
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def update_record(item = nil, fatal: true, **opt, &blk)
    not_implemented 'CANNOT HANDLE item' if item # TODO: ???
    not_implemented 'CANNOT HANDLE blk'  if blk  # TODO: ???
    return super if blk
    authorize_item(item)
    wf_single(event: :submit, **opt)
  end

  # Retrieve the indicated Upload record(s) for the '/delete' page.
  #
  # @param [any, nil] items           To #search_records
  # @param [Hash]     opt             Passed to #wf_single.
  #
  # @raise [RangeError]               If :page is not valid.
  #
  # @return [Array<Upload,String>]    NOTE: not Paginator::Result
  #
  # @see UploadWorkflow::Single::Remove::States#on_removing_entry
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def delete_records(items = nil, **opt, &blk)
    not_implemented 'CANNOT HANDLE items' if items # TODO: ???
    not_implemented 'CANNOT HANDLE blk'   if blk   # TODO: ???
    return super if blk
    authorized_session
    opt.reverse_merge!(rec: :unset, data: identifier)
    wf_single(event: :remove, **opt)
  end

  # Remove the indicated EMMA submission(s) by deleting the associated Upload
  # records and removing the associated entries from the EMMA Unified Index.
  #
  # @param [any, nil] items
  # @param [Boolean]  fatal           If *false* do not #raise_failure.
  # @param [Hash]     opt             Passed to #wf_single.
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Destroyed Upload records.
  #
  # @see UploadWorkflow::Single::Remove::States#on_removed_entry
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def destroy_records(items = nil, fatal: true, **opt, &blk)
    not_implemented 'CANNOT HANDLE items' if items # TODO: ???
    not_implemented 'CANNOT HANDLE blk'   if blk   # TODO: ???
    return super if blk
    authorized_session
    opt.reverse_merge!(rec: :unset, data: identifier, start_state: :removing)
    wf_single(event: :submit, variant: :remove, **opt)&.map do |item|
      if !item.is_a?(Upload)
        item
      elsif authorized_self_or_org_manager(item, fatal: false)
        item
      else
        "no authorization to remove #{item}"
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Re-create an EMMA submission that had been canceled.
  #
  def renew_record
    authorize_item
    wf_single(rec: :unset, event: :create)
  end

  # Re-start editing an EMMA submission.
  #
  def reedit_record
    authorize_item
    wf_single(event: :edit)
  end

  # Create a temporary record from provided data.
  #
  # @param [Hash, String, nil] fields
  # @param [Hash]              opt    Additional/replacement field values.
  #
  # @return [Upload]                  An un-persisted Upload record.
  #
  def temporary_record(fields = nil, **opt)
    fields = json_parse(fields)&.compact_blank
    opt.reverse_merge!(fields) if fields.present?
    Upload.new(opt)
  end

  # A record representation including URL of the remediated content file.
  #
  # @param [Upload] rec
  #
  # @return [Hash]
  #
  def record_value(rec)
    {
      submission_id: rec.submission_id,
      created_at:    rec.created_at,
      updated_at:    rec.updated_at,
      user_id:       rec.uid,
      user:          User.account_name(rec),
      file_url:      get_s3_public_url(rec),
      file_data:     safe_json_parse(rec.file_data),
      emma_data:     rec.emma_metadata,
    }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Refine authorization based on the specific item data.
  #
  # @param [Upload, Hash, nil] item
  # @param [Hash]              opt    Field value condition(s).
  #
  # @return [void]
  #
  def authorize_item(item = nil, **opt)
    return if administrator?
    opt.reverse_merge!(workflow_parameters)
    item &&= Upload.instance_for(item)
    item ||= Upload.instance_for(opt.slice(:id, :submission_id))
    authorized_self_or_org_manager(item, **opt)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # Gather information to create an upload workflow instance.
  #
  # @param [String, Integer, :unset, nil] rec
  # @param [Hash, String, :unset, nil]    data
  # @param [Hash]                         opt   To workflow initializer except:
  #
  # @option opt [Symbol] :from        Default: `#calling_method`.
  # @option opt [Symbol] :event
  #
  # @return [any, nil]                @see UploadWorkflow::Single#results
  #
  # @see UploadWorkflow::Single#generate
  #
  def wf_single(rec: nil, data: nil, **opt)
    from  = opt.delete(:from)&.to_sym || calling_method
    event = opt.delete(:event)&.to_s&.delete_suffix('!')&.to_sym
    raise "#{__method__}: missing :from"           unless from
    raise "#{__method__}: #{from}: missing :event" unless event
    rec  = (rec  || db_id || identifier unless rec  == :unset)
    data = (data || workflow_parameters unless data == :unset)
    opt[:variant] ||= event if UploadWorkflow::Single.variant?(event)
    opt[:user]    ||= @user
    opt[:params]  ||= workflow_parameters
    opt[:options] ||= model_options
    # noinspection RubyMismatchedArgumentType
    @workflow = UploadWorkflow::Single.generate(rec, **opt)
    @workflow.send("#{event}!", data)
    raise_failure(from, @workflow.failures) if @workflow.failures?
    @workflow.results
  rescue Workflow::Error => error
    raise UploadWorkflow::SubmitError.new(error)
  end

  # Determine whether the workflow state of the indicated item can be advanced.
  #
  # @param [String, Integer, nil] rec
  # @param [Hash]                 opt
  #
  # @return [Array<String>]       @see UploadWorkflow::Single#wf_check_status
  #
  # @see UploadWorkflow::Single#check_status
  #
  def wf_single_check(rec: nil, **opt)
    opt.delete(:from)
    rec           ||= db_id || identifier
    opt[:user]    ||= @user
    opt[:params]  ||= workflow_parameters
    opt[:options] ||= model_options
    opt[:html]      = params[:format].blank? || (params[:format] == 'html')
    # noinspection RubyMismatchedArgumentType
    @workflow = UploadWorkflow::Single.check_status(rec, **opt)
    @workflow.results
  rescue Workflow::Error => error
    raise UploadWorkflow::SubmitError.new(error)
  end

  # ===========================================================================
  # :section: Workflow - Bulk
  # ===========================================================================

  public

  # Gather information to create a bulk upload workflow instance.
  #
  # @param [Array, :unset, nil] rec
  # @param [Array, :unset, nil] data
  # @param [Hash]               opt   To workflow initializer except for:
  #
  # @option opt [Symbol] :from        Default: `#calling_method`.
  # @option opt [Symbol] :event
  #
  # @return [Array<Upload,String>]    @see UploadWorkflow::Bulk#results
  #
  # @see UploadWorkflow::Bulk#generate
  #
  def wf_bulk(rec: nil, data: nil, **opt)
    from  = opt.delete(:from)&.to_sym || calling_method
    event = opt.delete(:event)&.to_s&.delete_suffix('!')
    raise "#{__method__}: missing :from"           unless from
    raise "#{__method__}: #{from}: missing :event" unless event
    rec   = (rec == :unset) ? [] : (rec || []) # TODO: transaction record?
    data  = [] if data == :unset
    unless data
      data = upload_bulk_post_params or raise_failure(from)
      data << { base_url: request.base_url }
      opt[:control] ||= params[:src] || params[:source]
    end
    opt[:variant] ||= event if UploadWorkflow::Bulk.variant?(event)
    opt[:user]    ||= @user
    opt[:params]  ||= workflow_parameters
    opt[:options] ||= model_options
    @workflow = UploadWorkflow::Bulk.generate(rec, **opt)
    @workflow.send("#{event}!", *data)
    raise_failure(from, @workflow.failures) if @workflow.failures?
    @workflow.results
  rescue Workflow::Error => error
    raise UploadWorkflow::SubmitError.new(error)
  end

  # Produce flash error messages for failures that did not abort the workflow
  # step but did affect the outcome (e.g. for bulk uploads where some of the
  # original files could not be acquired).
  #
  # @param [Workflow] wf
  #
  def wf_check_partial_failure(wf = @workflow)
    return if (problems = wf.failures).blank?
    post_response(problems, redirect: false, xhr: false)
  end

  # ===========================================================================
  # :section: Workflow - Re-index
  # ===========================================================================

  public

  # Default batch size for #reindex_submissions
  #
  # @type [Integer]
  #
  DEFAULT_REINDEX_BATCH = 100

  # reindex_submissions
  #
  # @param [Array<Upload,String>] entries
  # @param [Hash, nil]            opt       To Upload#get_relation except for:
  #
  # @option opt [Boolean] :atomic           Passed to #reindex_record.
  # @option opt [Boolean] :dryrun           Passed to #reindex_record.
  # @option opt [Integer] :size             Default: `#DEFAULT_REINDEX_BATCH`.
  #
  # @return [Array<(Array<String>, Array<String>)>]  Succeeded/failed
  #
  def reindex_submissions(*entries, **opt)
    opt[:meth] ||= __method__
    local = opt.extract!(:atomic, :dryrun, :size)
    size  = positive(local[:size]) || DEFAULT_REINDEX_BATCH
    if entries.blank?
      update_null_state_records unless local[:dryrun]
      opt[:repository] ||= EmmaRepository.default
      opt[:state]      ||= [:completed, nil]
    else
      opt.slice!(:meth)
    end
    successes = []
    failures  = []
    Upload.get_relation(*entries, **opt).each_slice(size) do |items|
      sids, fails = reindex_record(items, **local, meth: opt[:meth])
      successes.concat(sids)
      failures.concat(fails)
      break if local[:atomic] && failures.present?
    end
    return successes, failures
  end

  # ===========================================================================
  # :section: Workflow - Re-index
  # ===========================================================================

  protected

  # Older completed submissions did not update the :state column.  This method
  # upgrades those records to the current practice.
  #
  # @param [Symbol] new_state
  #
  # @return [void]
  #
  def update_null_state_records(new_state = :completed)
    Upload.where(state: nil).update_all(state: new_state)
  end

  # Cause all of the listed items to be re-indexed.
  #
  # @param [Upload, Array<Upload>, ActiveRecord::Relation] list
  # @param [Boolean]                                       atomic
  # @param [Boolean]                                       dryrun
  # @param [Symbol]                                        meth     Caller.
  #
  # @return [Array<(Array<String>,Array<String>)>]   Succeeded sids / fail msgs
  #
  def reindex_record(list, atomic: false, dryrun: false, meth: __method__, **)
    successes = []
    failures  = []
    bad       = []
    list      = Array.wrap(list)
    sids      = list.map { Upload.sid_value(_1) }

    unless dryrun
      result = ingest_api.put_records(*list)
      errors = result.exec_report.error_table
      Log.debug { "#{meth}: put_records result: #{result.inspect}" }
      Log.info  { "#{meth}: result.errors: #{errors.inspect}" }
      if (by_index = errors.select { _1.is_a?(Integer) }).present?
        by_index.transform_keys! { |idx| sids[idx-1] }
        failures.concat by_index.map { |sid, msg| FlashPart.new(sid, msg) }
        bad.concat      by_index.keys
        errors = errors.except(*by_index.keys)
      end
      failures << errors if errors.present?
      Log.info { "#{meth}: failed sids:    #{bad.inspect}" }
      Log.info { "#{meth}: failed entries: #{failures.inspect}" }
    end

    if failures.blank?
      # === All succeeded
      Log.info { "#{meth}: accepted sids:  #{sids.inspect}" }
      successes = sids

    elsif atomic || bad.blank?
      # === General failure -- nothing to retry
      successes = []

    elsif (list = list.reject { bad.include?(_1.submission_id) }).present?
      # === Retry with the batch of non-failed items
      successes, new_failures = reindex_record(list, meth: meth)
      failures << new_failures

    end
    return successes, failures
  end

  # ===========================================================================
  # :section: ResponseConcern overrides
  # ===========================================================================

  public

  def default_fallback_location = upload_index_path

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  protected

  # Create an Options instance from the current parameters.
  #
  # @return [Upload::Options]
  #
  def get_model_options
    Upload::Options.new(request_parameters)
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
  # @return [Upload::Paginator]
  #
  def pagination_setup(paginator: Upload::Paginator, **opt)
    # noinspection RubyMismatchedReturnType
    super
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [any, nil] list            Default: `paginator.page_items`
  # @param [Hash]     opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = nil, **opt)
    opt.reverse_merge!(wrap: :entries)
    super
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Upload, Hash] item
  # @param [Hash]         opt
  #
  # @return [Hash]
  #
  def show_values(item = @item, **opt)
    item = item.try(:to_h) || {} unless item.is_a?(Hash)
    data = (safe_json_parse(item[:file_data]) || {} if item[:file_data])
    item = item.merge(file_data: data) if data
    super
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # If the :show endpoint is given an :id which is actually a specification for
  # multiple items then there is a redirect to :index.
  #
  # @return [void]
  #
  def index_redirect
    return unless identifier&.to_s&.match?(/[^[:alnum:]]/)
    # noinspection RailsParamDefResolve
    redirect_to action: :index, selected: identifier
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Response values for de-serializing download information to JSON or XML.
  #
  # @param [String,nil] url
  #
  # @return [Hash{Symbol=>String,nil}]
  #
  def download_values(url)
    { url: url }
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
