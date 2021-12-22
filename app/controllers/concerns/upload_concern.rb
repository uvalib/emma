# app/controllers/concerns/upload_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/http'

# Support methods for the "/upload" controller.
#
module UploadConcern

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Csv
  include Emma::Json

  include UploadWorkflow::Properties

  include ParamsHelper
  include FlashHelper

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include PaginationConcern
    # :nocov:
  end

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

  # URL parameters involved in pagination.                                      # NOTE: to EntryConcern::ENTRY_PAGE_PARAMS
  #
  # @type [Array<Symbol>]
  #
  UPLOAD_PAGE_PARAMS = %i[page start offset limit].freeze

  # URL parameters involved in form submission.                                 # NOTE: to EntryConcern::ENTRY_FORM_PARAMS
  #
  # @type [Array<Symbol>]
  #
  UPLOAD_FORM_PARAMS = %i[selected field-group cancel].freeze

  # POST/PUT/PATCH parameters from the entry form that are not relevant to the  # NOTE: to EntryConcern::IGNORED_ENTRY_FORM_PARAMS
  # create/update of an Upload instance.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_UPLOAD_FORM_PARAMS = (UPLOAD_PAGE_PARAMS + UPLOAD_FORM_PARAMS).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def upload_params                                                             # NOTE: to EntryConcern#entry_params
    @upload_params ||= get_upload_params
  end

  # Get URL parameters relevant to the current operation.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [Hash{Symbol=>Any}]
  #
  def get_upload_params(p = nil)                                                # NOTE: to EntryConcern#get_entry_params
    prm = url_parameters(p)
    prm.except!(*IGNORED_UPLOAD_FORM_PARAMS)
    prm.deep_symbolize_keys!
    reject_blanks(prm)
  end

  # Extract POST parameters that are usable for creating/updating an Upload
  # instance.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [Hash{Symbol=>Any}]
  #
  # == Implementation Notes
  # The value `params[:upload][:emma_data]` is ignored because it reports the
  # original metadata values that were supplied to the edit form.  The value
  # `params[:upload][:file]` is ignored if it is blank or is the JSON
  # representation of an empty object ("{}") -- this indicates an editing
  # submission where metadata is being changed but the uploaded file is not
  # being replaced.
  #
  def upload_post_params(p = nil)                                               # NOTE: to EntryConcern#entry_post_params
    prm  = p ? get_upload_params(p) : upload_params
    data = safe_json_parse(prm.delete(:upload), default: {})
    file = data[:file]
    prm[:file_data] = file unless file.blank? || (file == '{}')
    prm[:base_url]  = request.base_url
    prm[:revert]  &&= safe_json_parse(prm[:revert])
    @upload_params  = reject_blanks(prm)
  end

  # Extract POST parameters and data for bulk operations.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  # @param [ActionDispatch::Request, nil]            req Def: `#request`.
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  #
  # @return [Array<Hash>]
  #
  def upload_bulk_post_params(p = nil, req = nil)                               # NOTE: to EntryConcern#entry_bulk_post_params
    prm = p ? get_upload_params(p) : upload_params
    src = prm[:src] || prm[:source]
    opt = src ? { src: src } : { data: (req || request) }
    Array.wrap(fetch_data(**opt)).map(&:symbolize_keys)
  end

  # workflow_parameters
  #
  # @return [Hash]
  #
  def workflow_parameters                                                       # NOTE: to EntryConcern#entry_request_params (sorta)
    result = { id: @db_id, user_id: @user&.id }
    result.compact!
    result.merge!(upload_post_params)
    result.except!(:selected)
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
  # @raise [RuntimeError]             If both *src* and *data* are present.
  #
  # @return [nil]                     If both *src* and *data* are missing.
  # @return [Hash]
  # @return [Array<Hash>]
  #
  def fetch_data(**opt)                                                         # NOTE: to EntryConcern
    __debug_items("UPLOAD #{__method__}", binding)
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

  # URL parameters associated with item/entry identification.                   # NOTE: to EntryConcern
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_PARAMS = %i[id selected submission_id].freeze

  # Extract the best-match URL parameter which represents an item identifier.
  #
  # The @identifier member variable contains the original item specification,
  # if one was provided, and not the array of IDs represented by it.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [String]                  Value of @identifier.
  # @return [nil]                     No param from #IDENTIFIER_PARAMS found.
  #
  def set_identifiers(p = nil)                                                  # NOTE: to EntryConcern
    prm = url_parameters(p)
    id, sel, sid = prm.values_at(*IDENTIFIER_PARAMS).map(&:presence)
    @db_id = (sel.to_i if digits_only?(sel)) || (id.to_i if digits_only?(id))
    @identifier = sel || sid || id
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
  # @param [Array<String,Array>] items  Default: `@identifier`.
  # @param [Hash]                opt    Passed to Upload#search_records;
  #                                       default: `#upload_params` if no
  #                                       *items* are given.
  #
  # @raise [UploadWorkflow::SubmitError]  If :page is not valid.
  #
  # @return [Hash]
  #
  def find_or_match_records(*items, **opt)                                      # NOTE: to EntryConcern#find_or_match_entries
    items = items.flatten.compact
    items << @identifier if items.blank? && @identifier.present?

    # If neither items nor field queries were given, use request parameters.
    if items.blank? && (opt[:groups] != :only)
      opt = upload_params.merge(opt) if opt.except(*SEARCH_ONLY_PARAMS).blank?
    end
    opt[:limit] ||= 20 # TODO: Default page size for Upload index.
    opt[:page]  ||= 0  # Start at the first page by default.

    # Disallow experimental database WHERE predicates unless privileged.
    opt.slice!(*FIND_OR_MATCH_PARAMS) unless current_user&.administrator?

    # Select records for the current user unless a different user has been
    # specified (or all records if specified as '*', 'all', or 'false').
    user = opt.delete(:user)
    user = opt.delete(:user_id) || user || @user
    user = user.to_s.strip.downcase if user.is_a?(String) || user.is_a?(Symbol)
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
  # @param [String, Hash, Upload] id
  #
  # @raise [UploadWorkflow::SubmitError]  If *item* not found.
  #
  # @return [Upload, nil]
  #
  # @see Upload#get_record
  #
  def get_record(id)                                                            # NOTE: to EntryConcern#get_entry
    if (result = Upload.get_record(id))
      result
    elsif Upload.id_term(id).values.first.blank?
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
    rec  = (rec  || @db_id || @identifier unless rec  == :unset)
    data = (data || workflow_parameters unless data == :unset)
    opt[:variant] ||= event if UploadWorkflow::Single.variant?(event)
    opt[:user]    ||= @user
    opt[:params]  ||= workflow_parameters
    opt[:no_sim]    = true if UploadWorkflow::Single::SIMULATION # TODO: remove
    @workflow = UploadWorkflow::Single.generate(rec, **opt)
    @workflow.send("#{event}!", data)
    failure(from, @workflow.failures) if @workflow.failures?
    @workflow.results
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
    rec          ||= @db_id || @identifier
    opt[:user]   ||= @user
    opt[:params] ||= workflow_parameters
    opt[:no_sim]   = true if UploadWorkflow::Single::SIMULATION # TODO: remove
    opt[:html]     = params[:format].blank? || (params[:format] == 'html')
    # noinspection RubyMismatchedArgumentType
    @workflow = UploadWorkflow::Single.check_status(rec, **opt)
    @workflow.results
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
    opt[:no_sim]    = true if UploadWorkflow::Bulk::SIMULATION # TODO: remove
    @workflow = UploadWorkflow::Bulk.generate(rec, **opt)
    @workflow.send("#{event}!", *data)
    failure(from, @workflow.failures) if @workflow.failures?
    @workflow.results
  end

  # Produce flash error messages for failures that did not abort the workflow
  # step but did affect the outcome (e.g. for bulk uploads where some of the
  # original files could not be acquired).
  #
  # @param [Workflow] wf
  #
  def wf_check_partial_failure(wf = @workflow)
    return if (problems = wf.failures).blank?
    post_response(nil, problems, redirect: false, xhr: false)
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
  # @return [(Array<String>, Array<String>)]  Succeeded/failed
  #
  def reindex_submissions(*entries, **opt)
    opt, sql_opt = partition_hash(opt, :atomic, :meth, :dryrun, :size)
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
  # @return [(Array<String>,Array<String>)]   Succeeded sids / failure messages
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
  # :section: PaginationConcern overrides
  # ===========================================================================

  public

  # Finish setting of pagination values based on the result list and original
  # URL parameters.
  #
  # @param [Hash] result              From #find_or_match_records.
  # @param [Hash] opt                 Passed to #next_page_path.
  #
  # @return [void]
  #
  # @see PaginationConcern#pagination_finalize
  #
  def pagination_finalize(result, **opt)                                        # NOTE: to EntryConcern
    self.page_items   = result[:list]
    self.page_size    = result[:limit]
    self.page_offset  = result[:offset]
    self.total_items  = result[:total]
    first, last, page = result.values_at(:first, :last, :page)
    self.next_page    = (url_for(opt.merge(page: (page + 1)))     unless last)
    self.prev_page    = (url_for(opt.merge(page: (page - 1)))     unless first)
    self.first_page   = (url_for(opt.except(*UPLOAD_PAGE_PARAMS)) unless first)
    self.prev_page    = first_page if page == 2
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a response to a POST.
  #
  # @param [Symbol, Integer, Exception]                            status
  # @param [Exception, String, FlashPart, Array<String,FlashPart>] item
  # @param [String, FalseClass]       redirect
  # @param [Boolean]                  xhr       Override `request.xhr?`.
  # @param [Symbol]                   meth      Calling method.
  #
  # @return [void]
  #
  #--
  # == Variations
  #++
  #
  # @overload post_response(status, items, redirect: nil, xhr: nil, meth: nil)
  #   @param [Symbol, Integer]                            status
  #   @param [String, FlashPart, Array<String,FlashPart>] items
  #   @param [String, FalseClass]                         redirect
  #   @param [Boolean]                                    xhr
  #   @param [Symbol]                                     meth
  #
  # @overload post_response(status, error, redirect: nil, xhr: nil, meth: nil)
  #   @param [Symbol, Integer]        status
  #   @param [Exception]              error
  #   @param [String, FalseClass]     redirect
  #   @param [Boolean]                xhr
  #   @param [Symbol]                 meth
  #
  # @overload post_response(error, redirect: nil, xhr: nil, meth: nil)
  #   @param [Exception]              error
  #   @param [String, FalseClass]     redirect
  #   @param [Boolean]                xhr
  #   @param [Symbol]                 meth
  #
  def post_response(status, item = nil, redirect: nil, xhr: nil, meth: nil)     # NOTE: to EntryConcern
    meth ||= calling_method
    __debug_items("UPLOAD #{meth} #{__method__}", binding)
    unless status.is_a?(Symbol) || status.is_a?(Integer)
      status, item = [nil, status]
    end

    xhr       = request_xhr? if xhr.nil?
    html      = !xhr || redirect.present?
    report    = item.presence && ExecReport[item]
    status  ||= report&.http_status || :bad_request
    message   = report&.render(html: html)&.presence
    # noinspection RubyMismatchedArgumentType
    message ||= UploadWorkflow::Errors.make_label(item, default: '')

    opt = { meth: meth, status: status }

    if html
      if %i[ok found].include?(status) || (200..399).include?(status)
        flash_success(*message, **opt)
      else
        flash_failure(*message, **opt)
      end
      case redirect
        when false  then # no redirect
        when String then redirect_to(redirect)
        else             redirect_back(fallback_location: upload_index_path)
      end
    elsif message.present?
      head status, 'X-Flash-Message': flash_xhr(*message, **opt)
    else
      head status
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    if base.is_a?(ApplicationController)

      # In order to override #pagination_finalize this must be...
      included_after(base, PaginationConcern, this: THIS_MODULE)

      # =======================================================================
      # :section: Helpers - methods exposed for use in views
      # =======================================================================

      helper_method *UploadWorkflow::Properties.public_instance_methods(false)

    end

    include IngestConcern

  end

end

__loading_end(__FILE__)
