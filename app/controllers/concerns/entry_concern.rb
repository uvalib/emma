# app/controllers/concerns/entry_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/entry" controller.
#
# @!method paginator
#   @return [Entry::Paginator]
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module EntryConcern

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

  MIME_REGISTRATION =                                                           # NOTE: from UploadConcern
    FileNaming.format_classes.values.each(&:register_mime_types)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters associated with item/entry identification.                   # NOTE: from UploadConcern
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_PARAMS = Entry::Options::IDENTIFIER_PARAMS

  # URL parameters associated with POST data.
  #
  # @type [Array<Symbol>]
  #
  DATA_PARAMS = Entry::Options::DATA_PARAMS

  # The entry identified in URL parameters either as :selected or :id.
  #
  # @return [String, Integer, nil]
  #
  def identifier
    entry_params unless defined?(@identifier)
    @identifier
  end

  # The Entry record identified in URL parameters.
  #
  # @return [Integer, nil]
  #
  def entry_id
    entry_params unless defined?(@entry_id)
    @entry_id
  end

  # The Phase record identified in URL parameters.
  #
  # @return [Integer, nil]
  #
  def phase_id
    entry_params unless defined?(@phase_id)
    @phase_id
  end

  # The Action record identified in URL parameters.
  #
  # @return [Integer, nil]
  #
  def action_id
    entry_params unless defined?(@action_id)
    @action_id
  end

  # URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>*}]
  #
  def entry_params                                                              # NOTE: from UploadConcern#upload_params
    @entry_params ||= request.get? ? get_entry_params : entry_post_params
  end

  # Get URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>*}]
  #
  def get_entry_params                                                          # NOTE: from UploadConcern#get_upload_params
    model_options.get_model_params.tap do |prm|
      id, sel, sid = prm.values_at(*IDENTIFIER_PARAMS).map(&:presence)
      @identifier = sel || sid || id
      @entry_id   = [sel, id].compact.find { |v| digits_only?(v) }&.to_i
      @phase_id   = positive(prm[:phase_id])
      @action_id  = positive(prm[:action_id])
      prm[:user]  = @user if @user && !prm[:user] && !prm[:user_id] # TODO: should this be here?
    end
  end

  # Extract POST parameters that are usable for creating/updating an Entry
  # instance.
  #
  # @return [Hash{Symbol=>*}]
  #
  # == Implementation Notes
  # The value `params[:entry][:emma_data]` is ignored because it reports the
  # original metadata values that were supplied to the edit form.  The value
  # `params[:entry][:file]` is ignored if it is blank or is the JSON
  # representation of an empty object ("{}") -- this indicates an editing
  # submission where metadata is being changed but the uploaded file is not
  # being replaced.
  #
  def entry_post_params                                                         # NOTE: from UploadConcern#upload_post_params
    model_options.model_post_params.tap do |prm|
      prm[:base_url] = request.base_url
      extract_hash!(prm, *DATA_PARAMS).each_pair do |k, v|
        next unless (v &&= safe_json_parse(v)).is_a?(Hash)
        next unless v[:id].present?
        next unless (id = positive(v[:id]))
        case k
          when :action then @action_id = id
          when :phase  then @phase_id  = id
          else              @entry_id  = id
        end
      end
      id, sel, sid = prm.values_at(*IDENTIFIER_PARAMS).map(&:presence)
      @identifier  = sel || sid || id
      @entry_id  ||= [sel, id].compact.find { |v| digits_only?(v) }&.to_i
      @phase_id  ||= prm[:phase_id]
      @action_id ||= prm[:action_id]
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
  def entry_bulk_post_params                                                    # NOTE: from UploadConcern#upload_bulk_post_params
    prm = entry_post_params
    opt = extract_hash!(prm, :src, :source, :data)
    opt[:src]  = opt.delete(:source) if opt.key?(:source)
    opt[:data] = request             if opt.blank?
    opt[:type] = prm.delete(:type)&.to_sym
    fetch_data(**opt) || []
  end

  # entry_request_params
  #
  # @param [Entry, Hash{Symbol=>*}, *] entry
  # @param [Hash{Symbol=>*}, nil]      prm
  #
  # @return [Array<(Entry, Hash{Symbol=>*})>]
  # @return [Array<(Any, Hash{Symbol=>*})>]
  #
  def entry_request_params(entry, prm = nil)                                    # NOTE: from UploadConcern#workflow_parameters (sorta)
    entry, prm = [nil, entry] if entry.is_a?(Hash)
    prm ||= entry_params
    return entry, prm
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Parameters used by Entry#search_records.                                    # NOTE: from UploadConcern
  #
  # @type [Array<Symbol>]
  #
  SEARCH_RECORDS_PARAMS = Entry::SEARCH_RECORDS_OPTIONS

  # Entry#search_records parameters that specify a distinct search query.       # NOTE: from UploadConcern
  #
  # @type [Array<Symbol>]
  #
  SEARCH_ONLY_PARAMS = (SEARCH_RECORDS_PARAMS - %i[offset limit]).freeze

  # Parameters used by #find_by_match_records or passed on to                   # NOTE: from UploadConcern
  # Entry#search_records.
  #
  # @type [Array<Symbol>]
  #
  FIND_OR_MATCH_PARAMS = (
    SEARCH_RECORDS_PARAMS + %i[group state edit_state user user_id edit_user]
  ).freeze

  # Locate and filter Entry records.
  #
  # @param [Array<String,Integer,Array>] items  Def: `EntryConcern#identifier`.
  # @param [Hash]                       opt     Passed to Entry#search_records;
  #                                               default: `#entry_params` if
  #                                               no *items* are given.
  #
  # @raise [Record::SubmitError]        If :page is not valid.
  #
  # @return [Hash{Symbol=>*}]
  #
  def find_or_match_entries(*items, **opt)                                      # NOTE: from UploadConcern#find_or_match_records
    items = items.flatten.compact
    items << identifier if items.blank? && identifier.present?

    # If neither items nor field queries were given, use request parameters.
    if items.blank? && (opt[:groups] != :only)
      opt = entry_params.merge(opt) if opt.except(*SEARCH_ONLY_PARAMS).blank?
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
=begin # TODO: Entry doesn't have state - Entry.phases do
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
=begin # TODO: Entry doesn't have state - Entry.phases do
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
    opt.delete(:groups) # TODO: upload -> entry

    Entry.search_records(*items, **opt)

  rescue RangeError => error

    # Re-cast as a SubmitError so that EntryController#index redirects to the
    # main index page instead of the root page.
    raise Record::SubmitError.new(error)

  end

  # Return with the specified Entry record.
  #
  # @param [String, Hash, Entry, nil] item  Default: `EntryConcern#identifier`.
  # @param [Hash]                     opt   Passed to Entry#find_record.
  #
  # @option opt [Boolean] :no_raise     If *true*, return *nil* if not found.
  #
  # @raise [Record::StatementInvalid]   If :id/:sid not given.
  # @raise [Record::NotFound]           If *item* was not found.
  #
  # @return [Entry]                     Or possibly *nil* if *no_raise*.
  #
  def get_entry(item = nil, **opt)                                              # NOTE: from UploadConcern#get_record
    # noinspection RubyMismatchedReturnType
    Entry.find_record((item || identifier), **opt)
  end

  # Get Entry data from the production service.
  #
  # @param [String] sid               Submission ID of the item.
  # @param [String] host              Base URL of production service.
  #
  # @return [Entry]                   Object created from received data.
  # @return [nil]                     Bad data and/or no object created.
  #
  def proxy_get_entry(sid, host)                                                # NOTE: from UploadConcern#proxy_get_record
    data = sid && Faraday.get("#{host}/entry/show/#{sid}.json").body
    data = json_parse(data) || {}
    data = data[:response]  || data
    Entry.new(data) if data.present?
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # For the 'new' endpoint, generate and persist a Phase::Create record and a
  # temporary (un-persisted) Entry instance based on its attributes.
  #
  # @param [Entry, Hash{Symbol=>*}, nil] item   If present, used as a template.
  # @param [Hash{Symbol=>*}, nil]        opt    Default: `#get_entry_params`.
  #
  # @raise [ActiveRecord::RecordInvalid]    Phase record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Phase record creation halted.
  #
  # @return [Entry]                         Un-persisted Entry instance.
  #
  def new_entry(item = nil, opt = nil)
    entry, opt = entry_request_params(item, opt)
    opt   = opt.merge(from: entry) if entry
    phase = Phase::Create.start_submission(**opt)
    Entry.new(from: phase)
  end

  # For the 'create' endpoint, update the Phase record created above and create # TODO: NOTE: used in place of Record::Submittable::SubmissionMethods#entry_create
  # and persist a new Entry instance
  #
  # @param [Entry, Hash{Symbol=>*}, nil] item   If present, used as a template.
  # @param [Hash{Symbol=>*}, nil]        opt    Default: `#get_entry_params`.
  #
  # @raise [Record::StatementInvalid]       If submission ID was invalid.
  # @raise [Record::NotFound]               If Phase::Create record not found.
  # @raise [Record::SubmitError]            Invalid workflow transition.
  # @raise [ActiveRecord::RecordInvalid]    Update failed due to validations.
  # @raise [ActiveRecord::RecordNotSaved]   Update halted due to callbacks.
  #
  # @return [Entry]                         New persisted Entry instance.
  #
  def create_entry(item = nil, opt = nil)
    __debug_items("ENTRY WF #{__method__}", binding)
    entry, opt = entry_request_params(item, opt)
    opt   = opt.merge(from: entry) if entry
    phase = Phase::Create.finish_submission(**opt)
    Entry.create!(from: phase).tap { |new_entry| phase.entry = new_entry }
  end

  # For the 'edit' endpoint, generate and persist a Phase::Edit record and a    # TODO: NOTE: used in place of Record::Submittable::SubmissionMethods#entry_edit
  # temporary (un-persisted) instance based on its attributes.
  #
  # @param [Entry, Hash{Symbol=>*}, nil] item   If present, used as a template.
  # @param [Hash{Symbol=>*}, nil]        opt    Default: `#get_entry_params`.
  #
  # @raise [Record::SubmitError]            If the Entry could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Phase record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Phase record creation halted.
  #
  # @return [Entry]
  #
  def edit_entry(item = nil, opt = nil)
    __debug_items("ENTRY WF #{__method__}", binding)
    item, opt = entry_request_params(item, opt)
    get_entry(item, **opt).tap do |entry|
      entry.generate_phase(:Edit, **opt)
    end
  end

  # For the 'update' endpoint, get the matching Entry and update it from its
  # most recent Phase::Edit.
  #
  # @param [Entry, Hash{Symbol=>*}, nil] item   If present, used as a template.
  # @param [Hash{Symbol=>*}, nil]        opt    Default: `#get_entry_params`.
  #
  # @raise [Record::NotFound]               If the Entry could not be found.
  # @raise [Record::SubmitError]            If the Phase could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Entry record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Entry record update halted.
  #
  # @return [Entry]
  #
  def update_entry(item = nil, opt = nil)
    item, opt = entry_request_params(item, opt)
    get_entry(item, **opt).tap do |entry|
      if (phase = entry.phases.where(type: :Edit).order(:created_at).last)
        entry.update!(from: phase)
      else
        failure("No Phase::Edit for Entry #{entry.id}") # TODO: I18n
      end
    end
  end

  # For the 'delete' endpoint...
  #
  # @param [String, Entry, Array, nil] entries
  # @param [Hash, nil]                 opt   Default: `#get_entry_params`.
  #
  # @raise [RangeError]               If :page is not valid.
  #
  # @return [Hash{Symbol=>*}]         From Record::Searchable#search_records.
  #
  def delete_entry(entries = nil, opt = nil)
    entries, opt = entry_request_params(entries, opt)
    id_opt    = extract_hash!(opt, :ids, :id)
    entries ||= id_opt.values.first
    opt.except!(:force, :emergency, :truncate)
    Entry.search_records(*entries, **opt)
  end

  # For the 'destroy' endpoint... # TODO: ?
  #
  # @param [String, Entry, Array, nil] entries
  # @param [Hash, nil]                 opt
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Destroyed entries.
  #
  def destroy_entry(entries = nil, opt = nil)                                   # NOTE: from UploadWorkflow::Actions#wf_remove_items
    entries, opt = entry_request_params(entries, opt)
    opt.reverse_merge!(model_options.all)
    id_opt    = extract_hash!(opt, :ids, :id)
    entries ||= id_opt.values.first
    succeeded, failed = Entry.batch_entry_remove(*entries, **opt)
    failure(:destroy, failed.uniq) if failed.present?
    succeeded
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # For the 'renew' endpoint, find the most recent create and return with the
  # related Entry.
  #
  # @param [Entry, Hash{Symbol=>*}, nil] item   If present, used as a template.
  # @param [Hash{Symbol=>*}, nil]        opt    Default: `#get_entry_params`.
  #
  # @raise [Record::StatementInvalid]   If *sid*/opt[:submission_id] invalid.
  # @raise [Record::NotFound]           If Phase::Create could not be found.
  #
  # @return [Entry]                     A record from the 'entries' table.
  #
  def renew_entry(item = nil, opt = nil)
    entry, opt = entry_request_params(item, opt)
    sid   = Entry.sid_value((entry || identifier), **opt)
    phase = Phase::Create.latest_for_sid(sid, **opt)
    Entry.new(from: phase)
  end

  # For the 'reedit' endpoint, find the most recent edit and return with the
  # related Entry.
  #
  # @param [Entry, Hash{Symbol=>*}, nil] item   If present, used as a template.
  # @param [Hash{Symbol=>*}, nil]        opt    Default: `#get_entry_params`.
  #
  # @raise [Record::StatementInvalid]   If *sid*/opt[:submission_id] invalid.
  # @raise [Record::NotFound]           If Phase could not be found or created.
  #
  # @return [Entry]
  #
  def reedit_entry(item = nil, opt = nil)
    entry, opt = entry_request_params(item, opt)
    sid   = Entry.sid_value((entry || identifier), **opt)
    phase = Phase::Edit.latest_for_sid(sid, **opt.merge(no_raise: true))
    phase&.entry&.take || renew_entry(**opt)
  end

  # For the 'cancel' endpoint, ... # TODO: ?
  #
  # @param [Entry, Hash{Symbol=>*}, nil] item   If present, used as a template.
  # @param [Hash{Symbol=>*}, nil]        opt    Default: `#get_entry_params`.
  #
  # @raise [Record::NotFound]                   If *item* was not found.
  # @raise [Record::SubmitError]                If Entry could not be found.
  # @raise [ActiveRecord::RecordNotDestroyed]   If Phase could not be removed.
  #
  # @return [Entry]
  #
  def cancel_entry(item = nil, opt = nil)
    item, opt = entry_request_params(item, opt)
    get_entry(item, no_raise: true, **opt).tap do |entry|
      unless (phase = entry.current_phase)
        sid   = entry.sid_value || opt[:submission_id]
        phase =
          Phase::Edit.where(submission_id: sid).order(:updated_at).last ||
            Phase::Create.where(submission_id: sid).order(:created_at).last
        failure("No record for submission #{sid.inspect}") unless phase # TODO: I18n
      end
      phase.destroy!
    end
  end

  # Get a description of the status of the Entry, if it exists, or a temporary
  # (un-persisted) Entry based on Phase lookup.
  #
  # @param [Entry, Hash{Symbol=>*}, nil] item   If present, used as a template.
  # @param [Hash{Symbol=>*}, nil]        opt    Default: `#get_entry_params`.
  #
  # @option opt [Boolean] :html       Default: false.
  # @option opt [Phase]   :phase
  #
  # @raise [RuntimeError]             If neither Entry nor Phase could be found
  #
  # @return [Array<String>]
  #
  def check_entry(item = nil, opt = nil)                                        # NOTE: from UploadWorkflow::Single::Actions#wf_check_status
    entry, opt = entry_request_params(item, opt)
    local, opt = partition_hash(opt, :html)
    opt[:no_raise] = true unless opt.key?(:no_raise)
    if (entry = get_entry(entry, **opt))
      note  = entry.describe_status
    else
      sid   = Entry.sid_value(identifier, **opt)
      phase = Phase.latest_for_sid(sid, **opt)
      entry = Entry.new(from: phase)
      note  = entry.describe_status(phase: phase)
    end
    note = note.upcase_first
    note = ERB::Util.h(note) if local[:html]
    if local[:html] && false # TODO: testing - remove
      opt.delete(:no_raise)
      parts = {}
      parts[:options] = ERB::Util.h(opt.inspect) if opt.present?
      parts[:record] =
        ERB::Util.h(pretty_json(entry)).tap { |rec|
          rec.gsub!(/:( +)/) { ':' + $1.gsub(/ /, '&nbsp;&nbsp;') }
          rec.gsub!(/^/, '&nbsp;&nbsp;')
          rec.gsub!(/\n/, '<br/>')
          rec.sub!(/\A&nbsp;&nbsp;/, '')
          rec.sub!(/(&nbsp;)*}<br\/>\z/, '}')
        }.html_safe
      parts.each_pair do |label, value|
        note << "<br/><br/>#{label} = #{value}".html_safe
      end
    end
    Array.wrap(note)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # Upload file to AWS S3 Shrine :cache.
  #
  # @param [Entry, Hash{Symbol=>*}, nil] entry
  # @param [Hash{Symbol=>*}, nil]        opt    Def: `#entry_request_params`.
  #
  # @raise [Record::SubmitError]      If the record could not be found.
  #
  # @return [Array<(Integer, Hash{String=>Any}, Array<String>)>]
  #
  # @see Phase::Create#upload!
  # @see Phase::Edit#upload!
  #
  def upload_file(entry = nil, opt = nil)
    entry, opt = entry_request_params(entry, opt)
    sid   = opt[:submission_id].presence or raise 'No submission ID'
    phase = entry&.phases&.where(submission_id: sid)&.last
    phase ||= Phase.creates(submission_id: sid).last
    failure("No record for submission ID #{sid.inspect}") unless phase
    phase.upload!(request).tap do
      failure(phase.exec_report) unless phase.exec_report.blank?
    end
  end

  # ===========================================================================
  # :section: Workflow - Bulk
  # ===========================================================================

  public

  # bulk_new_entries
  #
  # @return [Any]
  #
  def bulk_new_entries
    prm = get_entry_params
    if prm.slice(:src, :source, :manifest).present?
      post make_path(bulk_create_entry_path, **prm)
    else
      # TODO: bulk_new_entries
    end
  end

  # bulk_create_entries
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Created entries.
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def bulk_create_entries
    data = entry_bulk_post_params << { base_url: request.base_url }
    succeeded = []
    failed    = []
    # TODO: bulk_create_entries
    failure(:create, failed.uniq) if failed.present?
    succeeded
  end

  # bulk_edit_entries
  #
  # @return [Any]
  #
  def bulk_edit_entries
    prm = get_entry_params
    if prm.slice(:src, :source, :manifest).present?
      put make_path(bulk_update_entry_path, **prm)
    else
      # TODO: bulk_edit_entries
    end
  end

  # bulk_update_entries
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Modified entries.
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def bulk_update_entries
    data = entry_bulk_post_params << { base_url: request.base_url }
    succeeded = []
    failed    = []
    # TODO: bulk_update_entries
    failure(:update, failed.uniq) if failed.present?
    succeeded
  end

  # bulk_delete_entries
  #
  # @return [Any]
  #
  def bulk_delete_entries
    prm = get_entry_params
    if prm.slice(:src, :source, :manifest).present?
      delete make_path(bulk_destroy_entry_path, **prm)
    else
      # TODO: bulk_delete_entries
    end
  end

  # bulk_destroy_entries
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Removed entries.
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def bulk_destroy_entries
    data = entry_bulk_post_params << { base_url: request.base_url }
    succeeded = []
    failed    = []
    # TODO: bulk_destroy_entries
    failure(:destroy, failed.uniq) if failed.present?
    succeeded
  end

  # bulk_check_entries
  #
  # @return [Any]
  #
  # @note Currently unused.
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def bulk_check_entries
    prm = get_entry_params
    # TODO: bulk_check_entries
  end

  # Default batch size for #reindex_submissions
  #
  # @type [Integer]
  #
  DEFAULT_REINDEX_BATCH = 100

  # reindex_submissions
  #
  # @param [Array<Model,String>] entries
  # @param [Hash, nil]           opt          To Entry#get_relation except for:
  #
  # @option opt [Boolean] :atomic             Passed to #reindex_record.
  # @option opt [Boolean] :dryrun             Passed to #reindex_record.
  # @option opt [Symbol]  :meth               Passed to #reindex_record.
  #
  # @return [Array<(Array<String>, Array<String>)>]  Succeeded/failed
  #
  def reindex_submissions(*entries, **opt)
    sql_opt = remainder_hash!(opt, :atomic, :meth, :dryrun, :size)
    opt[:meth] ||= __method__
    if entries.blank?
      sql_opt[:repository] ||= EmmaRepository.default
      relation = Entry.get_relation(**sql_opt)
    else
      relation = Entry.get_relation(*entries)
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

  # Cause all of the listed items to be re-indexed.
  #
  # @param [Model, Array<Model>, ActiveRecord::Relation] list
  # @param [Boolean]                                     atomic
  # @param [Boolean]                                     dryrun
  # @param [Symbol]                                      meth     Caller.
  #
  # @return [Array<(Array<String>,Array<String>)>]   Succeeded sids / fail msgs
  #
  def reindex_record(list, atomic: false, dryrun: false, meth: __method__, **)
    successes = []
    failures  = []
    bad       = []
    list      = Array.wrap(list)
    sids      = list.map { |item| Entry.sid_value(item) }

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
    opt[:tag]      ||= "ENTRY #{opt[:meth]}"
    opt[:fallback] ||= entry_index_path
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
    ExceptionHelper.failure(problem, value, model: :entry)
  end

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  protected

  # Create a @model_options instance from the current parameters.
  #
  # @return [Entry::Options]
  #
  def set_model_options
    @model_options = Entry::Options.new(request_parameters)
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
  # @return [Entry::Paginator]
  #
  def pagination_setup(paginator: Entry::Paginator, **opt)
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
