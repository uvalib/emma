# app/controllers/concerns/entry_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/http'

# Support methods for the "/entry" controller.
#
module EntryConcern

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Csv
  include Emma::Json

  include Record::Properties
  include Record::Exceptions

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

  MIME_REGISTRATION =                                                           # NOTE: from UploadConcern
    FileNaming.format_classes.values.each(&:register_mime_types)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters involved in pagination.                                      # NOTE: from UploadConcern#UPLOAD_PAGE_PARAMS
  #
  # @type [Array<Symbol>]
  #
  ENTRY_PAGE_PARAMS = %i[page start offset limit].freeze

  # URL parameters involved in form submission.                                 # NOTE: from UploadConcern#UPLOAD_FORM_PARAMS
  #
  # @type [Array<Symbol>]
  #
  ENTRY_FORM_PARAMS = %i[selected field-group cancel].freeze

  # POST/PUT/PATCH parameters from the entry form that are not relevant to the  # NOTE: from UploadConcern#IGNORED_UPLOAD_FORM_PARAMS
  # create/update of an Entry instance.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_ENTRY_FORM_PARAMS = (ENTRY_PAGE_PARAMS + ENTRY_FORM_PARAMS).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def entry_params                                                              # NOTE: from UploadConcern#upload_params
    @entry_params ||=
      get_entry_params.tap do |prm|
        @action_id ||= prm[:action_id]
        @phase_id  ||= prm[:phase_id]
        @entry_id  ||= prm[:entry_id] || prm[:id]
      end
  end

  # Get URL parameters relevant to the current operation.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [Hash{Symbol=>Any}]
  #
  def get_entry_params(p = nil)                                                 # NOTE: from UploadConcern#get_upload_params
    prm = url_parameters(p)
    prm.except!(*IGNORED_ENTRY_FORM_PARAMS)
    prm.reject! { |k, _| k.start_with?('edit_') }                               # TODO: temporary until JavaScript upload -> entry
    prm.deep_symbolize_keys!
    prm[:user] = @user if @user && !prm[:user] && !prm[:user_id] # TODO: should this be here?
    reject_blanks(prm)
  end

  # Extract POST parameters that are usable for creating/updating an Entry
  # instance.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [Hash{Symbol=>Any}]
  #
  # == Implementation Notes
  # The value `params[:entry][:emma_data]` is ignored because it reports the
  # original metadata values that were supplied to the edit form.  The value
  # `params[:entry][:file]` is ignored if it is blank or is the JSON
  # representation of an empty object ("{}") -- this indicates an editing
  # submission where metadata is being changed but the uploaded file is not
  # being replaced.
  #
  def entry_post_params(p = nil)                                                # NOTE: from UploadConcern#upload_post_params
    prm = p ? get_entry_params(p) : entry_params
    if (fields = json_parse(prm.delete(:entry)))
      prm[:file_data] = json_parse(fields.delete(:file))
      prm[:emma_data] = json_parse(fields.delete(:emma_data))
      prm[:revert]    = json_parse(fields.delete(:revert_data)) # TODO: revert?
      prm.merge!(fields)
      @entry_id ||= fields[:id] if p.nil?
    end
    prm[:base_url] = request.base_url
    @entry_params  = reject_blanks(prm)
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
  def entry_bulk_post_params(p = nil, req = nil)                                # NOTE: from UploadConcern#upload_bulk_post_params
    prm = p ? get_entry_params(p) : entry_params
    src = prm[:src] || prm[:source] || prm[:manifest]
    opt = src ? { src: src } : { data: (req || request) }
    Array.wrap(fetch_data(**opt)).map(&:symbolize_keys)
  end

  # entry_request_params
  #
  # @param [Entry, Hash, *] entry
  # @param [Hash, *]        opt
  #
  # @return [(Entry, Hash)]
  # @return [(*, Hash)]
  #
  def entry_request_params(entry, opt)                                          # NOTE: from UploadConcern#workflow_parameters (sorta)
    entry, opt = [nil, entry] if entry.is_a?(Hash)
    opt ||= request.get? ? get_entry_params : entry_post_params
    return entry, opt
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
  def fetch_data(**opt)                                                         # NOTE: from UploadConcern
    __debug_items("ENTRY #{__method__}", binding)
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

  # URL parameters associated with item/entry identification.                   # NOTE: from UploadConcern
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_PARAMS = %i[id selected submission_id].freeze

  # URL parameters associated with POST data.
  #
  # @type [Array<Symbol>]
  #
  DATA_PARAMS = %i[entry phase action].freeze

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
  def set_identifiers(p = nil)                                                  # NOTE: from UploadConcern
    prm = url_parameters(p)
    data, prm = partition_hash(prm, *DATA_PARAMS)
    data.each_pair do |k, v|
      next unless (v &&= safe_json_parse(v)).is_a?(Hash)
      if v[:id].present?
        case k
          when :action then @action_id = v[:id]
          when :phase  then @phase_id  = v[:id]
          else              @entry_id  = v[:id]
        end
      end
      prm[k] = v
    end
    id, sel, sid = prm.values_at(*IDENTIFIER_PARAMS).map(&:presence)
    id          ||= @entry_id
    @entry_id   ||= (sel.to_i if digits_only?(sel))
    @entry_id   ||= (id.to_i  if digits_only?(id))
    @identifier   = sel || sid || id
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
  # @param [Array<String,Array>] items  Default: `@identifier`.
  # @param [Hash]                opt    Passed to Entry#search_records;
  #                                       default: `#entry_params` if no
  #                                       *items* are given.
  #
  # @raise [Record::SubmitError]        If :page is not valid.
  #
  # @return [Hash]
  #
  def find_or_match_entries(*items, **opt)                                      # NOTE: from UploadConcern#find_or_match_records
    items = items.flatten.compact
    items << @identifier if items.blank? && @identifier.present?

    # If neither items nor field queries were given, use request parameters.
    if items.blank? && (opt[:groups] != :only)
      opt = entry_params.merge(opt) if opt.except(*SEARCH_ONLY_PARAMS).blank?
    end
    opt[:limit] ||= 20 # TODO: Default page size for Entry index.
    opt[:page]  ||= 0  # Start at the first page by default.

    # Disallow experimental database WHERE predicates unless privileged.
    opt.slice!(*FIND_OR_MATCH_PARAMS) unless current_user&.administrator?

    # Select records for the current user unless a different user has been
    # specified (or all records if specified as '*', 'all', or 'false').
    user = opt.delete(:user)
    user = opt.delete(:user_id) || user || @user
    user = user.to_s.strip.downcase if user.is_a?(String) || user.is_a?(Symbol)
    user = User.find_record(user)   unless %w(* 0 all false).include?(user)
    opt[:user_id] = user.id         if user.is_a?(User) && user.id.present?

    # Limit records to those in the given state (or records with an empty state
    # field if specified as 'nil', 'empty', or 'missing').
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

  # Return with the specified Entry record or *nil* if one could not be found.
  #
  # @param [String, Hash, Entry, nil] item  Default: @identifier.
  # @param [Hash]                     opt   Passed to Entry#find_record.
  #
  # @raise [Record::StatementInvalid]   If :id/:sid not given.
  # @raise [Record::NotFound]           If *item* was not found.
  #
  # @return [Entry]
  #
  # noinspection RubyMismatchedReturnType
  def get_entry(item = nil, **opt)                                              # NOTE: from UploadConcern#get_record
    Entry.find_record((item || @identifier), **opt)
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
  # @param [Entry, Hash, nil] item          If present, used as a template.
  # @param [Hash, nil]        opt           Default: `#get_entry_params`.
  #
  # @raise [ActiveRecord::RecordInvalid]    Phase record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Phase record creation halted.
  #
  # @return [Entry]                         Un-persisted Entry instance.
  #
  def new_entry(item = nil, opt = nil)
    item, opt = entry_request_params(item, opt)
    # noinspection RubyNilAnalysis
    opt   = opt.merge(from: item) if item
    phase = Phase::Create.start_submission(**opt)
    Entry.new(from: phase)
  end

  # For the 'create' endpoint, update the Phase record created above and create # TODO: NOTE: used in place of Record::Submittable::SubmissionMethods#entry_create
  # and persist a new Entry instance
  #
  # @param [Entry, Hash, nil] item          If present, used as a template.
  # @param [Hash, nil]        opt           Default: `#get_entry_params`.
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
    # noinspection RubyNilAnalysis
    opt   = opt.merge(from: entry) if entry
    phase = Phase::Create.finish_submission(**opt)
    Entry.create!(from: phase).tap { |new_entry| phase.entry = new_entry }
  end

  # For the 'edit' endpoint, generate and persist a Phase::Edit record and a    # TODO: NOTE: used in place of Record::Submittable::SubmissionMethods#entry_edit
  # temporary (un-persisted) instance based on its attributes.
  #
  # @param [Entry, Hash, nil] item
  # @param [Hash, nil]        opt           Default: `#get_entry_params`.
  #
  # @raise [Record::SubmitError]            If the Entry could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Phase record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Phase record creation halted.
  #
  # @return [Entry]                         A record from the 'entries' table.
  #
  def edit_entry(item = nil, opt = nil)
    __debug_items("ENTRY WF #{__method__}", binding)
    item, opt = entry_request_params(item, opt)
    # noinspection RubyMismatchedReturnType
    get_entry(item, **opt).tap { |entry| entry&.generate_phase(:Edit, **opt) }
  end

  # For the 'update' endpoint, get the matching Entry and update it from its
  # most recent Phase::Edit.
  #
  # @param [Entry, Hash, nil] item
  # @param [Hash, nil]        opt           Default: `#get_entry_params`.
  #
  # @raise [Record::NotFound]               If the Entry could not be found.
  # @raise [Record::SubmitError]            If the Phase could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Entry record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Entry record update halted.
  #
  # @return [Entry]                         Updated Entry instance.
  #
  def update_entry(item = nil, opt = nil)
    item, opt = entry_request_params(item, opt)
    # noinspection RubyMismatchedReturnType
    get_entry(item, **opt) do |entry|
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
  # @return [Hash]                    From Record::Searchable#search_records.
  #
  def delete_entry(entries = nil, opt = nil)
    entries, opt = entry_request_params(entries, opt)
    id_opt,  opt = partition_hash(opt, :ids, :id)
    entries ||= id_opt.values.first
    # noinspection RubyNilAnalysis
    opt.except!(:force, :emergency, :truncate)
    Entry.search_records(*entries, **opt)
  end

  # For the 'destroy' endpoint... # TODO: ?
  #
  # @param [String, Entry, Array] entries
  # @param [Hash, nil]            opt   Default: `#get_entry_params`.
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Destroyed entries.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def destroy_entry(entries = nil, opt = nil)                                   # NOTE: from UploadWorkflow::Actions#wf_remove_items
    entries, opt = entry_request_params(entries, opt)
    id_opt,  opt = partition_hash(opt, :ids, :id)
    entries ||= id_opt.values.first
    opt[:force]     = force_delete     unless opt.key?(:force)
    opt[:emergency] = emergency_delete unless opt.key?(:emergency)
    opt[:truncate]  = truncate_delete  unless opt.key?(:truncate)
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
  # @param [Entry, Hash, nil] entry
  # @param [Hash, nil]        opt       Default: `#get_entry_params`.
  #
  # @raise [Record::StatementInvalid]   If *sid*/opt[:submission_id] invalid.
  # @raise [Record::NotFound]           If Phase::Create could not be found.
  #
  # @return [Entry]                     A record from the 'entries' table.
  #
  def renew_entry(entry = nil, opt = nil)
    entry, opt = entry_request_params(entry, opt)
    sid   = Entry.sid_value((entry || @identifier), **opt)
    phase = Phase::Create.latest_for_sid(sid, **opt)
    Entry.new(from: phase)
  end

  # For the 'reedit' endpoint, find the most recent edit and return with the
  # related Entry.
  #
  # @param [Entry, Hash, nil] entry
  # @param [Hash, nil]        opt     Default: `#get_entry_params`.
  #
  # @raise [Record::StatementInvalid]   If *sid*/opt[:submission_id] invalid.
  # @raise [Record::NotFound]           If Phase could not be found or created.
  #
  # @return [Entry]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def reedit_entry(entry = nil, opt = nil)
    entry, opt = entry_request_params(entry, opt)
    sid   = Entry.sid_value((entry || @identifier), **opt)
    phase = Phase::Edit.latest_for_sid(sid, **opt.merge(no_raise: true))
    phase&.entry&.take || renew_entry(**opt)
  end

  # For the 'cancel' endpoint, ... # TODO: ?
  #
  # @param [Entry, Hash, nil] entry
  # @param [Hash, nil]        opt     Default: `#get_entry_params`.
  #
  # @raise [Record::SubmitError]                If Entry could not be found.
  # @raise [ActiveRecord::RecordNotDestroyed]   If Phase could not be removed.
  #
  # @return [Entry]
  # @return [nil]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def cancel_entry(entry = nil, opt = nil)
    entry, opt = entry_request_params(entry, opt)
    entry   = get_entry(entry, no_raise: true, **opt)
    sid     = entry&.sid_value || opt[:submission_id]
    phase   = entry&.current_phase
    phase ||= Phase::Edit.where(submission_id: sid).order(:updated_at).last
    phase ||= Phase::Create.where(submission_id: sid).order(:created_at).last
    phase&.destroy! or failure("No record for submission #{sid.inspect}") # TODO: I18n
  end

  # Get a description of the status of the Entry, if it exists, or a temporary
  # (un-persisted) Entry based on Phase lookup.
  #
  # @param [Entry, Hash, nil] item
  # @param [Hash, nil]        opt     Default: `#get_entry_params`.
  #
  # @option opt [Boolean] :html       Default: false.
  # @option opt [Phase]   :phase
  #
  # @raise [RuntimeError]             If neither Entry nor Phase could be found
  #
  # @return [Array<String>]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def check_entry(item = nil, opt = nil)                                        # NOTE: from UploadWorkflow::Single::Actions#wf_check_status
    entry, opt = entry_request_params(item, opt)
    local, opt = partition_hash(opt, :html)
    opt[:no_raise] = true unless opt.key?(:no_raise)
    if (entry = get_entry(entry, **opt))
      note  = entry.describe_status
    else
      sid   = Entry.sid_value(@identifier, **opt)
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
  # @param [Entry, Hash, nil] entry
  # @param [Hash, nil]        opt     Default: `#entry_post_params`.
  #
  # @raise [Record::SubmitError]      If the record could not be found.
  #
  # @return [(Integer, Hash{String=>*}, Array<String>)]
  #
  # @see Phase::Create#upload!
  # @see Phase::Edit#upload!
  #
  def upload_file(entry = nil, opt = nil)
    entry, opt = entry_request_params(entry, opt)
    sid   = opt[:submission_id].presence or raise 'No submission ID'
    phase = entry&.phases&.where(submission_id: sid)&.order(:created_at)&.last
    phase ||= Phase.creates(submission_id: sid).order(:created_at).last
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
  # @param [Hash, nil] opt
  #
  # @return [*]
  #
  def bulk_new_entries(opt = nil)
    opt ||= get_entry_params
    # noinspection RubyNilAnalysis
    if opt.slice(:src, :source, :manifest).present?
      post make_path(bulk_create_entry_path, **opt)
    else
      # TODO: ???
    end
  end

  # bulk_create_entries
  #
  # @param [Hash, nil] opt
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Created entries.
  #
  def bulk_create_entries(opt = nil)
    data = entry_bulk_post_params(opt) << { base_url: request.base_url }
    succeeded = []
    failed    = []
    # TODO: bulk_create_entries
    failure(:create, failed.uniq) if failed.present?
    succeeded
  end

  # bulk_edit_entries
  #
  # @param [Hash, nil] opt
  #
  # @return [*]
  #
  def bulk_edit_entries(opt = nil)
    opt ||= get_entry_params
    # noinspection RubyNilAnalysis
    if opt.slice(:src, :source, :manifest).present?
      put make_path(bulk_update_entry_path, **opt)
    else
      # TODO: bulk_edit_entries
    end
  end

  # bulk_update_entries
  #
  # @param [Hash, nil] opt
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Modified entries.
  #
  def bulk_update_entries(opt = nil)
    data = entry_bulk_post_params(opt) << { base_url: request.base_url }
    succeeded = []
    failed    = []
    # TODO: bulk_update_entries
    failure(:update, failed.uniq) if failed.present?
    succeeded
  end

  # bulk_delete_entries
  #
  # @param [Hash, nil] opt
  #
  # @return [*]
  #
  def bulk_delete_entries(opt = nil)
    opt ||= get_entry_params
    # noinspection RubyNilAnalysis
    if opt.slice(:src, :source, :manifest).present?
      delete make_path(bulk_destroy_entry_path, **opt)
    else
      # TODO: bulk_delete_entries
    end
  end

  # bulk_destroy_entries
  #
  # @param [Hash, nil] opt
  #
  # @raise [RuntimeError]             If both :src and :data are present.
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Removed entries.
  #
  def bulk_destroy_entries(opt = nil)
    data = entry_bulk_post_params(opt) << { base_url: request.base_url }
    succeeded = []
    failed    = []
    # TODO: bulk_destroy_entries
    failure(:destroy, failed.uniq) if failed.present?
    succeeded
  end

  # bulk_check_entries
  #
  # @param [Hash, nil] opt
  #
  # @return [*]
  #
  def bulk_check_entries(opt = nil)
    opt ||= get_entry_params
    # TODO: bulk_check_entries
  end

  # ===========================================================================
  # :section: PaginationConcern overrides
  # ===========================================================================

  public

  # Finish setting of pagination values based on the result list and original
  # URL parameters.
  #
  # @param [Hash] result              From #find_or_match_entries.
  # @param [Hash] opt                 Passed to #next_page_path.
  #
  # @return [void]
  #
  # @see PaginationConcern#pagination_finalize
  #
  def pagination_finalize(result, **opt)                                        # NOTE: from UploadConcern
    self.page_items   = result[:list]
    self.page_size    = result[:limit]
    self.page_offset  = result[:offset]
    self.total_items  = result[:total]
    first, last, page = result.values_at(:first, :last, :page)
    self.next_page    = (url_for(opt.merge(page: (page + 1)))    unless last)
    self.prev_page    = (url_for(opt.merge(page: (page - 1)))    unless first)
    self.first_page   = (url_for(opt.except(*ENTRY_PAGE_PARAMS)) unless first)
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
  # == Variations
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
  def post_response(status, item = nil, redirect: nil, xhr: nil, meth: nil)     # NOTE: from UploadConcern
    meth ||= calling_method
    __debug_items("ENTRY #{meth} #{__method__}", binding)
    unless status.is_a?(Symbol) || status.is_a?(Integer)
      status, item = [nil, status]
    end

    xhr       = request_xhr? if xhr.nil?
    html      = !xhr || redirect.present?
    report    = item.presence && ExecReport[item]
    status  ||= report&.http_status || :bad_request
    message   = report&.render(html: html)&.presence
    message ||= Record::Rendering.make_label(item, default: '')

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
        else             redirect_back(fallback_location: entry_index_path)
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

    # In order to override #pagination_finalize this must be...
    included_after(base, PaginationConcern, this: THIS_MODULE)

    # =========================================================================
    # :section: Helpers - methods exposed for use in views
    # =========================================================================

    helper_method *Record::Properties.public_instance_methods(false)

  end

end

__loading_end(__FILE__)