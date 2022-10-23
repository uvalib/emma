# app/controllers/concerns/upload_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/upload" controller.
#
# @!method paginator
#   @return [Upload::Paginator]
#
module UploadConcern

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Json

  include ParamsHelper
  include FlashHelper
  include HttpHelper

  include ImportConcern
  include IngestConcern
  include OptionsConcern
  include ResponseConcern
  include PaginationConcern

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  public

  MIME_REGISTRATION =                                                           # NOTE: to EntryConcern
    FileNaming.format_classes.values.each(&:register_mime_types)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters associated with item/entry identification.                   # NOTE: to EntryConcern
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_PARAMS = Upload::Options::IDENTIFIER_PARAMS

  # The upload identified in URL parameters either as :selected or :id.
  #
  # @return [String, nil]
  #
  def identifier
    upload_params unless defined?(@identifier)
    @identifier
  end

  # The database ID of the upload identified in URL parameters.
  #
  # @return [Integer, nil]
  #
  def db_id
    upload_params unless defined?(@db_id)
    @db_id
  end

  # URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>*}]
  #
  def upload_params                                                             # NOTE: to EntryConcern#entry_params
    @upload_params ||= get_upload_params
  end

  # Get URL parameters relevant to the current operation.                       # NOTE: method now unused
  #
  # @return [Hash{Symbol=>*}]
  #
  def get_upload_params                                                         # NOTE: to EntryConcern#get_entry_params
    model_options.get_model_params.tap do |prm|
      id, sel, sid = prm.values_at(*IDENTIFIER_PARAMS).map(&:presence)
      @identifier ||= sel || sid || id
      @db_id      ||= [sel, id].find { |v| digits_only?(v) }&.to_i
    end
  end

  # Extract POST parameters that are usable for creating/updating an Upload
  # instance.
  #
  # @return [Hash{Symbol=>*}]
  #
  # == Implementation Notes
  # The value `params[:upload][:emma_data]` is ignored because it reports the
  # original metadata values that were supplied to the edit form.  The value
  # `params[:upload][:file]` is ignored if it is blank or is the JSON
  # representation of an empty object ("{}") -- this indicates an editing
  # submission where metadata is being changed but the uploaded file is not
  # being replaced.
  #
  def upload_post_params                                                        # NOTE: to EntryConcern#entry_post_params
    model_options.model_post_params.tap do |prm|
      prm[:base_url] = request.base_url
      id, sel, sid = prm.values_at(*IDENTIFIER_PARAMS).map(&:presence)
      @identifier  ||= sel || sid || id
      @db_id       ||= [sel, id].find { |v| digits_only?(v) }&.to_i
      @upload_params = prm
    end
  end

  # Extract POST parameters and data for bulk operations.
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  #
  # @return [Array<Hash{Symbol=>*}>]
  #
  # @see ImportConcern#fetch_data
  #
  def upload_bulk_post_params                               # NOTE: to EntryConcern#entry_bulk_post_params
    prm = upload_post_params
    opt = extract_hash!(prm, :src, :source, :data)
    opt[:src]  = opt.delete(:source) if opt.key?(:source)
    opt[:data] = request             if opt.blank?
    opt[:type] = prm.delete(:type)&.to_sym
    fetch_data(**opt) || []
  end

  # workflow_parameters
  #
  # @return [Hash{Symbol=>*}]
  #
  def workflow_parameters                                                       # NOTE: to EntryConcern#entry_request_params (sorta)
    result = { id: db_id, user_id: @user&.id }
    result.compact!
    result.merge!(upload_post_params)
    result.except!(:selected)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Parameters used by Upload#search_records.                                   # NOTE: to EntryConcern
  #
  # @type [Array<Symbol>]
  #
  SEARCH_RECORDS_PARAMS = Upload::SEARCH_RECORDS_OPTIONS

  # Upload#search_records parameters that specify a distinct search query.      # NOTE: to EntryConcern
  #
  # @type [Array<Symbol>]
  #
  SEARCH_ONLY_PARAMS = (SEARCH_RECORDS_PARAMS - %i[offset limit]).freeze

  # Parameters used by #find_by_match_records or passed on to                   # NOTE: to EntryConcern
  # Upload#search_records.
  #
  # @type [Array<Symbol>]
  #
  FIND_OR_MATCH_PARAMS = (
    SEARCH_RECORDS_PARAMS + %i[group state edit_state user user_id edit_user]
  ).freeze

  # Locate and filter Upload records.
  #
  # @param [Array<String,Array>] items  Default: `UploadConcern#identifier`.
  # @param [Hash]                opt    Passed to Upload#search_records;
  #                                       default: `#upload_params` if no
  #                                       *items* are given.
  #
  # @raise [UploadWorkflow::SubmitError]  If :page is not valid.
  #
  # @return [Hash{Symbol=>*}]
  #
  def find_or_match_records(*items, **opt)                                      # NOTE: to EntryConcern#find_or_match_entries
    items = items.flatten.compact
    items << identifier if items.blank? && identifier.present?

    # If neither items nor field queries were given, use request parameters.
    if items.blank? && (opt[:groups] != :only)
      opt = upload_params.merge(opt) if opt.except(*SEARCH_ONLY_PARAMS).blank?
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
    if user.is_a?(User)
      opt[:user_id]   = user.id  if user.id.present?
      opt[:edit_user] = user.uid if user.uid.present?
    end

    # Limit records to those in the given state (or records with an empty state
    # field if specified as 'nil', 'empty', or 'missing').
    if (state = opt.delete(:state).to_s.strip.downcase).present?
      if %w(empty false missing nil none null).include?(state)
        opt[:state] = nil
      else
        opt[:state] = state
        opt[:edit_state] ||= state
      end
    end

    # Limit by workflow status group.
    group = opt.delete(:group)
    group = group.split(/\s*,\s*/) if group.is_a?(String)
    group = Array.wrap(group).compact_blank
    if group.present?
      group.map!(&:downcase).map!(&:to_sym)
      if group.include?(:all)
        %i[state edit_state].each { |k| opt.delete(k) }
      else
        states =
          group.flat_map { |g|
            Upload::STATE_GROUP.dig(g, :states)
          }.compact.map(&:to_s)
        %i[state edit_state].each do |k|
          opt[k] = (Array.wrap(opt[k]) + states).uniq
          opt.delete(k) if opt[k].empty?
        end
      end
    end

    Upload.search_records(*items, **opt)

  rescue RangeError => error

    # Re-cast as a SubmitError so that UploadController#index redirects to the
    # main index page instead of the root page.
    raise UploadWorkflow::SubmitError.new(error)

  end

  # Return with the specified Upload record or *nil* if one could not be found.
  #
  # @param [String, Hash, Upload, nil] id   Default: UploadConcern#identifier.
  #
  # @raise [UploadWorkflow::SubmitError]    If *item* not found.
  #
  # @return [Upload, nil]
  #
  # @see Upload#get_record
  #
  def get_record(id = nil)                                                            # NOTE: to EntryConcern#get_entry
    id ||= identifier
    if (result = Upload.get_record(id))
      result
    elsif id.blank? || Upload.id_term(id).values.first.blank?
      failure(:file_id)
    else
      Log.warn { "#{__method__}: #{id}: non-existent record" }
      failure(:find, id)
    end
  end

  # Get item data from the production service.
  #
  # @param [String] sid               Submission ID of the item.
  # @param [String] host              Base URL of production service.
  #
  # @return [Upload]                  Object created from received data.
  # @return [nil]                     Bad data and/or no object created.
  #
  def proxy_get_record(sid, host)                                               # NOTE: to EntryConcern#proxy_get_entry
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
  # @return [Any]                     @see UploadWorkflow::Single#results
  #
  # @see UploadWorkflow::Single#generate
  #
  def wf_single(rec: nil, data: nil, **opt)
    from  = (opt.delete(:from) || calling_method)&.to_sym
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
    failure(from, @workflow.failures) if @workflow.failures?
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
    from  = (opt.delete(:from) || calling_method)&.to_sym
    event = opt.delete(:event)&.to_s&.delete_suffix('!')
    raise "#{__method__}: missing :from"           unless from
    raise "#{__method__}: #{from}: missing :event" unless event
    rec   = (rec == :unset) ? [] : (rec || []) # TODO: transaction record?
    data  = [] if data == :unset
    unless data
      data = upload_bulk_post_params or failure(from)
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
    failure(from, @workflow.failures) if @workflow.failures?
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
  # @option opt [Symbol]  :meth             Passed to #reindex_record.
  #
  # @return [Array<(Array<String>, Array<String>)>]  Succeeded/failed
  #
  def reindex_submissions(*entries, **opt)
    sql_opt = remainder_hash!(opt, :atomic, :meth, :dryrun, :size)
    opt[:meth] ||= __method__
    if entries.blank?
      update_null_state_records unless opt[:dryrun]
      sql_opt[:repository] ||= EmmaRepository.default
      sql_opt[:state]      ||= [:completed, nil]
      relation = Upload.get_relation(**sql_opt)
    else
      relation = Upload.get_relation(*entries)
    end
    successes = []
    failures  = []
    size      = positive(opt[:size]) || DEFAULT_REINDEX_BATCH
    relation.each_slice(size) do |items|
      sids, fails = reindex_record(items, **opt)
      successes += sids
      failures  += fails
      break if opt[:atomic] && failures.present?
    end
    return successes, failures
  end

  # ===========================================================================
  # :section: Workflow - Bulk
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
    sids      = list.map { |item| Upload.sid_for(item) }

    unless dryrun
      result = ingest_api.put_records(*list)
      errors = result.exec_report.error_table
      Log.debug { "#{meth}: put_records result: #{result.inspect}" }
      Log.info  { "#{meth}: result.errors: #{errors.inspect}" }
      if (by_index = errors.select { |k| k.is_a?(Integer) }).present?
        by_index.transform_keys! { |idx| sids[idx-1] }
        failures += by_index.map { |sid, msg| FlashPart.new(sid, msg) }
        bad      += by_index.keys
        errors    = errors.except(*by_index.keys)
      end
      failures << errors if errors.present?
      Log.info { "#{meth}: failed sids:    #{bad.inspect}" }
      Log.info { "#{meth}: failed entries: #{failures.inspect}" }
    end

    if failures.blank?
      # == All succeeded
      Log.info { "#{meth}: accepted sids:  #{sids.inspect}" }
      successes = sids

    elsif atomic || bad.blank?
      # == General failure -- nothing to retry
      successes = []

    elsif (list = list.reject { |i| bad.include?(i.submission_id) }).present?
      # == Retry with the batch of non-failed items
      successes, new_failures = reindex_record(list, meth: meth)
      failures << new_failures

    end
    return successes, failures
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
    opt[:tag]      ||= "UPLOAD #{opt[:meth]}"
    opt[:fallback] ||= upload_index_path
    super
  end

  # ===========================================================================
  # :section: ResponseConcern overrides
  # ===========================================================================

  protected

  # Render an item for display in a message.
  #
  # @param [Model, Hash, String, *] item
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
  # :section:
  # ===========================================================================

  protected

  # Raise an exception.
  #
  # @param [Symbol, String, Array<String>, ExecReport, Exception, nil] problem
  # @param [Any, nil]                                                  value
  #
  # @raise [UploadWorkflow::SubmitError]
  # @raise [ExecError]
  #
  # @see ExceptionHelper#failure
  #
  def failure(problem, value = nil)
    ExceptionHelper.failure(problem, value, model: :upload)
  end

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  protected

  # Create a @model_options instance from the current parameters.
  #
  # @return [Upload::Options]
  #
  def set_model_options
    @model_options = Upload::Options.new(request_parameters)
  end

  # ===========================================================================
  # :section: PaginationConcern overrides
  # ===========================================================================

  protected

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
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
