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
        prm.values_at(:submission_id, :id).find { |v| digits_only?(v) }&.to_i
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
        prm.values_at(:submission_id, :id).find { |v| digits_only?(v) }&.to_i
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
  # :section:
  # ===========================================================================

  public

  # Get item data from the production service.
  #
  # @param [String] sid               Submission ID of the item.
  # @param [String] host              Base URL of production service.
  #
  # @return [Upload]                  Object created from received data.
  # @return [nil]                     Bad data and/or no object created.
  #
  def proxy_get_record(sid, host)
    data = sid && Faraday.get("#{host}/upload/show/#{sid}.json").body
    data = json_parse(data) || {}
    data = data[:response]  || data
    Upload.new(data) if data.present?
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
    opt[:no_sim]    = true if UploadWorkflow::Single::SIMULATION # TODO: remove
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
    opt[:no_sim]    = true if UploadWorkflow::Single::SIMULATION # TODO: remove
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
    opt[:no_sim]    = true if UploadWorkflow::Bulk::SIMULATION # TODO: remove
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
    sids      = list.map { |item| Upload.sid_value(item) }

    unless dryrun
      result = ingest_api.put_records(*list)
      errors = result.exec_report.error_table
      Log.debug { "#{meth}: put_records result: #{result.inspect}" }
      Log.info  { "#{meth}: result.errors: #{errors.inspect}" }
      if (by_index = errors.select { |k| k.is_a?(Integer) }).present?
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

    elsif (list = list.reject { |i| bad.include?(i.submission_id) }).present?
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
  # :section: ResponseConcern overrides
  # ===========================================================================

  protected

  # Render an item for display in a message.
  #
  # @param [any, nil] item            Model, Hash, String
  #
  # @return [String]
  #
  def make_label(item, **opt)
    if item.is_a?(Upload)
      UploadWorkflow::Errors::RenderMethods.make_label(item, **opt)
    else
      super
    end
  end

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
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
