# app/models/upload_workflow/single.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class UploadWorkflow::Single < UploadWorkflow
  # Initial declaration to establish the namespace.
end

# =============================================================================
# :section: Auxiliary
# =============================================================================

public

module UploadWorkflow::Single::Errors
  include UploadWorkflow::Errors
end

module UploadWorkflow::Single::Properties
  include UploadWorkflow::Properties
  include UploadWorkflow::Single::Errors
end

# =============================================================================
# :section: Core
# =============================================================================

public

module UploadWorkflow::Single::External
  include UploadWorkflow::External
  include UploadWorkflow::Single::Properties
  include UploadWorkflow::Single::Events
end

# Workflow execution status information specific to single-item workflows.
#
module UploadWorkflow::Single::Data

  include Emma::Json

  include UploadWorkflow::Data
  include UploadWorkflow::Single::External

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The Upload record associated with this workflow.
  #
  # @return [Upload, nil]
  #
  attr_reader :record

  # ===========================================================================
  # :section: Workflow::Base::Data overrides
  # ===========================================================================

  public

  # The characteristic "return value" of the workflow after an event has been
  # registered.
  #
  # @return [Array<(Integer,Hash,Array<String>)>]   For :validating, :replacing
  # @return [Array<Upload,String>]                  For :removing, :removed
  # @return [Upload, nil]                           For all other states
  #
  def results
    @results ||= record
  end

  # If #record is *nil* then create it using *data*; otherwise update it using
  # *data*.
  #
  # @param [Upload, Hash, String, nil] data
  #
  # @return [Upload, nil]
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def set_data(data)
    data = super

    @existing = nil
    failed    = []

    # The semantics depend on whether a record has already been created or not.
    if @record

      # Update the existing record with the provided data.
      @existing = !@record.new_record?
      if data.nil?
        Log.debug { "#{__method__}: nil ignored for existing record" }
      elsif !data.is_a?(Upload) && !data.is_a?(Hash)
        Log.warn { "#{__method__}: #{data.class} invalid for existing record" }
        failed << "INTERNAL ERROR: data class #{data.class}" # TODO: I18n
      else
        opt = record_data(data)
        @record.update(opt)
      end

    else

      # Retrieve (or create) the record in the database table.
      if data.is_a?(Upload)
        # noinspection RubyMismatchedVariableType
        @record   = data
        @existing = !@record.new_record?

      elsif data.is_a?(Hash)
        opt = record_data(data)
        @record, failed = upload_edit(**opt)
        if @record
          @existing = true
        else
          @record, failed = upload_create(**opt)
          @existing = false if @record
        end

      elsif data.present?
        attribute = digits_only?(data) ? :id : :submission_id
        @record, failed = upload_edit(attribute => data)
        @existing = true if @record

      else
        Log.warn { "#{__method__}: not created: no identifier provided" }
      end

    end

    self.failures += failed if failed.present?

    return unless @record

    # Ensure that the record indicates the appropriate workflow phase.
    set_workflow_phase(workflow_phase, @record)

    # Until a record is persisted, the workflow state is held in the variable
    # defined in the Workflow module.
    if @workflow_state
      persisted = get_workflow_state(@record)
      unless @workflow_state == persisted
        Log.debug do
          "updating workflow state from '#{persisted}' to '#{@workflow_state}'"
        end
        persisted = set_workflow_state(@workflow_state, @record)
      end
      @workflow_state = nil if persisted
    end

    @record
  end

  alias_method :set_record, :set_data

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Fields not preserved by #record_data.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_UPLOAD_FIELDS = [
    Upload::WORKFLOW_PHASE_COLUMN,
    Upload::PRIMARY_STATE_COLUMN,
    Upload::SECONDARY_STATE_COLUMN
  ].freeze

  # Prepare record data for use in creating a new record or updating an
  # existing record.
  #
  # @param [Upload, Hash] data
  #
  # @return [Hash{Symbol=>Any}]
  #
  def record_data(data)
    data = data.attributes if data.is_a?(Upload)
    data.symbolize_keys.except!(*IGNORED_UPLOAD_FIELDS)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Clear the fields in an existing Upload record.
  #
  # @param [Upload, Hash, String, nil] data
  #
  # @return [Upload, nil]
  #
  def reset_record(data = nil)
    id = sid = nil
    # noinspection RubyCaseWithoutElseBlockInspection, RubyNilAnalysis
    case data
      when Upload
        (id = data.id) or (sid = data.submission_id)
        data = data.attributes.symbolize_keys.except(:id, :submission_id)
      when Hash
        ids, data = partition_hash(data.symbolize_keys, :id, :submission_id)
        (id = ids[:id]) or (sid = ids[:submission_id])
      when String
        digits_only?(data) ? (id = data) : (sid = data)
        data = nil
    end
    if !id && !sid && record
      (id = record.id) or (sid = record.submission_id)
    end
    data = {} unless data.is_a?(Hash)
    data[:reset] = true
    id ? (data[:id] = id) : (data[:submission_id] = sid)
    set_record(data)
  end

  # Create a new Upload record.
  #
  # @param [Upload, Hash, String, nil] data
  #
  # @return [Upload, nil]
  #
  def create_record(data = nil)
    set_record(data || {})
  end

  # Indicate whether a record was originally created by (or on behalf of) the
  # workflow (as opposed to an existing record acquired from the database).
  #
  # @return [Boolean, nil]
  #
  def existing_record
    @existing ||= nil
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the record is associated with an uploaded file.
  #
  def file_valid?
    record.present? && record.file_attacher.file.present?
  end

  # Indicate whether the EMMA metadata associated with the record is valid.
  #
  def metadata_valid?
    record.present? && record.valid?
  end

  # ===========================================================================
  # :section: Workflow::Base::Data overrides
  # ===========================================================================

  public

  # Indicate whether a record has been assigned.
  #
  def empty?
    super && record.blank?
  end

  # Indicate whether the item is valid.
  #
  def complete?
    super && file_valid? && metadata_valid?
  end

end

# New and overridden action methods specific to single-item upload workflows.
#
module UploadWorkflow::Single::Actions

  include Emma::Json

  include UploadWorkflow::Actions
  include UploadWorkflow::Single::Data

  # ===========================================================================
  # :section: UploadWorkflow::Actions overrides
  # ===========================================================================

  public

  # wf_start_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  # @see UploadWorkflow::Single::Data#set_record
  #
  def wf_start_submission(*event_args)
    __debug_items(binding)
    data = event_args.extract_options!.presence || event_args.first
    case existing_record
      when false then set_record(data)
      when true  then reset_record(data)
      else            create_record(data)
    end
  end

  # wf_validate_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  # @see UploadWorkflow::Single::Data#set_record
  #
  def wf_validate_submission(*event_args)
    __debug_items(binding)
    data = event_args.extract_options!.presence || event_args.first
    set_record(data)
    self.succeeded << record.id unless failures?
  end

  # wf_list_items
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_list_items(*event_args)
    __debug_items(binding)
    super
    self.results = succeeded
  end

  # wf_remove_items
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_remove_items(*event_args)
    __debug_items(binding)
    opt = event_args.extract_options!
    event_args << record if event_args.empty?
    super(*event_args, opt)
    self.results = succeeded
  end

  # wf_finalize_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_finalize_submission(*event_args)
    __debug_items(binding)
  end

  # wf_cancel_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_cancel_submission(*event_args)
    __debug_items(binding)
  end

  # wf_index_update
  #
  # @param [Array] _event_args        Ignored.
  #
  # @return [void]
  #
  def wf_index_update(*_event_args)
    __debug_items(binding)
    assert_record_present
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Upload file via Shrine and update failed/succeeded arrays.
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  # @see UploadWorkflow::Single::External#upload_file
  #
  def wf_upload_file(*event_args)                                               # NOTE: to Action::Store#upload!
    __debug_items(binding)
    opt = event_args.extract_options!.presence || event_args.first || {}
    opt[:meth] ||= calling_method

    # The return from Shrine will be the results of the workflow step.
    stat, _hdrs, body = self.results = upload_file(**opt)

    # Update status arrays accordingly.
    data = nil
    if stat.nil?
      self.failures  << 'missing env data'
    elsif stat != 200
      self.failures  << 'invalid file'
    elsif !record
      self.succeeded << 'no record' # TODO: should this be a failure?
    elsif (data = json_parse(body.first)&.except(:emma_data)&.to_json)
      self.succeeded << record.id
    else
      self.failures  << 'invalid file_data'
    end

    # Ensure that the record is updated now instead of waiting for the file
    # data to be returned when the form is submitted in case the submission is
    # canceled and the uploaded file needs to be removed from storage.
    record.update_column(record.file_data_column, data) if data
  end

  # Check workflow status to see whether it should advance.
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_check_status(*event_args)                                              # NOTE: to EntryConcern#check_entry
    opt  = event_args.extract_options!
    html = !false?(opt[:html])
    user = record.active_user
    repo = Upload.repository_name(record)
    sid  = "submission #{record.submission_id.inspect}"
    sub  = record.emma_native? ? sid : "#{repo} #{sid}"
    note =
      case curr_state
        when :starting    then "#{sub} - non-existent submission"
        when :creating    then "#{sub} is being created by #{user}"
        when :validating  then "#{sub} is being created by #{user}"
        when :submitting  then "#{sub} is being created by #{user}"
        when :submitted   then "#{sub} is being created by #{user}"
        when :editing     then "#{sub} is being modified by #{user}"
        when :replacing   then "#{sub} is being modified by #{user}"
        when :modifying   then "#{sub} is being modified by #{user}"
        when :modified    then "#{sub} is being modified by #{user}"
        when :removing    then "#{sub} is being removed"
        when :removed     then "#{sub} is being removed"
        when :scheduling  then "#{sub} is under review"
        when :assigning   then "#{sub} is under review"
        when :holding     then "#{sub} is under review"
        when :assigned    then "#{sub} is under review"
        when :reviewing   then "#{sub} is being reviewed by #{user}"
        when :staging     then "#{sub} is being submitted"
        when :unretrieved then wf_check_retrieved
        when :retrieved   then "#{sid} has been retrieved by #{repo}"
        when :indexing    then wf_check_indexed
        when :indexed     then "#{sub} is being indexed"
        when :completed   then "#{sub} is complete"
        else "Unexpected submission state: #{curr_state.inspect}"
      end
    note = note.upcase_first
    note = ERB::Util.h(note) if html
    if html && false # TODO: testing - remove
      args  = event_args
      parts = {}
      parts['event_args'] = ERB::Util.h(args.inspect) if args.present?
      parts['options']    = ERB::Util.h(opt.inspect)  if opt.present?
      parts['record'] =
        ERB::Util.h(pretty_json(record)).tap { |rec|
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
    self.results = self.succeeded = Array.wrap(note)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # When the workflow state of the record is :unretrieved, check the AWS S3
  # bucket to determine whether the submission has finally been picked up by
  # the member repository and removed from the queue.  If so, then advance the
  # workflow state.
  #
  # @return [String]
  #
  def wf_check_retrieved                                                        # NOTE: to Action::Queue#check_retrieved
    sid  = record.submission_id
    data = aws_api.list_records(record).values_at(sid).flatten

    # Advance workflow state if the test passes.
    done = data.blank?
    advance! if done

    # Return status.
    sub  = "submission #{sid.inspect}"
    repo = Upload.repository_name(record)
    if done
      "#{repo} is now processing #{sub}"
    else
      "#{sub} has not yet been retrieved by #{repo}"
    end
  end

  # When the workflow state of the record is :indexing, check to determine
  # whether index has finally received the update from the member repository.
  # If so then advance the workflow state.
  #
  # @return [String]
  #
  def wf_check_indexed                                                          # NOTE: to Action::Index#check_indexed
    sid  = record.submission_id
    rid  = record.emma_metadata[:emma_recordId]
    data = ingest_api.get_records(rid)

    # Advance workflow state if the test passes.
    done = data.present?
    advance! if done

    # Return status.
    sub = "submission #{sid.inspect}"
    sub = "#{Upload.repository_name(record)} #{sub}" unless record.emma_native?
    if done
      "the index service is now processing #{sub}"
    else
      "#{sub} has not yet been included in the index"
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Asset presence of an Upload record.
  #
  # @raise [RuntimeError]
  #
  # @return [TrueClass]
  #
  def assert_record_present
    record.present? or raise 'NO RECORD - INTERNAL WORKFLOW ERROR'
  end

  # Asset that the Upload record is EMMA-native.
  #
  # @raise [RuntimeError]
  #
  # @return [TrueClass]
  #
  def assert_emma_record
    assert_record_present
    record.emma_native? or raise 'NON-EMMA RECORD - INTERNAL WORKFLOW ERROR'
  end

end

module UploadWorkflow::Single::Simulation

  include UploadWorkflow::Simulation

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Simulated record properties.  (Always *nil* if `#SIMULATION` is *false*.)
  #
  # @return [RecordProperties]
  # @return [nil]
  #
  attr_reader :submission

  def set_submission(...)
    raise "#{__method__} only available if DEBUG_WORKFLOW is true"
  end

end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Single::Events
  include UploadWorkflow::Events
  include UploadWorkflow::Single::Simulation
end

# Overridden state transition methods specific to single-item upload workflows.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module UploadWorkflow::Single::States

  include UploadWorkflow::States
  include UploadWorkflow::Single::Events
  include UploadWorkflow::Single::Actions

  # ===========================================================================
  # :section: UploadWorkflow::States overrides
  # ===========================================================================

  public

  # Upon entering the :starting state.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_starting_entry(state, event, *event_args)
    super

    __debug_sim('The workflow is starting.')

    self
  end

  # Set the record 'phase' when leaving the :starting state.
  #
  # @param [Workflow::State] state        State that is being exited.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_starting_exit(state, event, *event_args)
    super

    unless event == :start

      __debug_sim("Using workflow #{self.class}")
      __debug_sim("with workflow_phase: #{workflow_phase.inspect}")
      __debug_sim("with variant_type:   #{variant_type.inspect}")
      __debug_sim("with record:         #{record.inspect}")

      set_workflow_phase(workflow_phase)

    end

    self
  end

  # ===========================================================================
  # :section: UploadWorkflow::States overrides - Review
  # ===========================================================================

  public

  # Upon entering the :scheduling state:
  #
  # The submission is being scheduled for review.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_scheduling_entry(state, event, *event_args)
    super

    # TODO: simulation - remove
    if simulating
      __debug_sim("[auto_review: #{submission.auto_review}]")
      auto_review = submission.auto_review
    else
      auto_review = false
    end

    # Determine whether the system should perform an automated review.
    unless simulating
      auto_review = record.auto_reviewable?
    end

    # TODO: simulation - remove
    if auto_review
      __debug_sim('SYSTEM will perform an automated review.')
    else
      __debug_sim('SYSTEM will determine a pool of reviewer(s).')
    end

    # Automatically transition to the next state based on submission status.
    if auto_review
      assign!  # NOTE: => :assigned
    else
      advance! # NOTE: => :assigning
    end
    self
  end

  # Upon entering the :assigning state:
  #
  # The submission is being assigned for review.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_assigning_entry(state, event, *event_args)
    super

    # Determine availability of appropriate reviewer(s).
    if simulating
      __debug_sim("[no_reviewers: #{submission.no_reviewers}]")
      can_proceed = !submission.no_reviewers
    else
      can_proceed = true
    end

    # TODO: simulation - remove
    if can_proceed
      __debug_sim('SYSTEM notifies the pool of available reviewer(s).')
    else
      __debug_sim('SYSTEM determined there are no reviewers available.')
    end

    # Automatically transition to the next state based on submission status.
    if can_proceed
      advance! # NOTE: => :assigned
    else
      hold!    # NOTE: => :holding
    end
    self
  end

  # Upon entering the :holding state:
  #
  # The system is waiting for a reviewer (or the review process is paused).
  #
  # The submission will remain in this state until the reviewer's action causes
  # the state to advance.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_holding_entry(state, event, *event_args)
    super

    if simulating

      task = ReviewerTask

      if event == :hold
        __debug_sim("Start #{task} to check for an available reviewer.")
        task.start
      end

      if task.check
        __debug_sim("The #{task} is checking...")
        timeout! # NOTE: => :holding

      elsif task.success
        __debug_sim("The #{task} has found a reviewer.")
        advance! # NOTE: => :assigning

      else
        __debug_sim("The #{task} still has NOT found a reviewer.")
        __debug_sim('SYSTEM notifies the user of submission status.')
        __debug_sim('SYSTEM notifies administrator of possible problem.')
        if task.restart
          __debug_sim("The #{task} is restarting.")
          timeout! # NOTE: => :holding
        else
          __debug_sim("The #{task} is terminated.")
          fail!    # NOTE: => :failed
        end
      end

    end

    self
  end

  # Upon entering the :assigned state:
  #
  # The submission has been assigned for review.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_assigned_entry(state, event, *event_args)
    super

    # Determine whether the system should perform an automated review.
    auto_review = false # TODO: auto-review?

    # Determine whether the system should perform an automated review.
    if simulating
      __debug_sim("[auto_review: #{submission.auto_review}]")
      auto_review = submission.auto_review # TODO: remove
    end

    # Determine whether the system should perform an automated review.
    unless simulating
      auto_review = record.auto_reviewable? if record
    end

    # TODO: simulation - remove
    if auto_review
      __debug_sim('SYSTEM is performing an automated review.')
    else
      __debug_sim('Waiting for reviewer to begin review.')
      __debug_sim('REVIEWER must `review!` to advance...')
    end

    # If the submission is to be reviewed by a human then it remains in this
    # state until a review claims it (i.e. starts a review).
    review! if auto_review # NOTE: => :reviewing

    self
  end

  # When leaving the :assigned state:
  #
  # The submission was assigned for review.
  #
  # @param [Workflow::State] state        State that is being exited.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_assigned_exit(state, event, *event_args)
    super

    unless event == :review
      changed = 'withdrawn'
      changed += ' pending edits' unless event == :cancel
      __debug_sim("Reviewer(s) notified the submission was #{changed}.")
    end

    self
  end

  # Upon entering the :reviewing state:
  #
  # The submission is under review.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_reviewing_entry(state, event, *event_args)
    super

    if !simulating || !submission.auto_review
      __debug_sim('[auto_review: false]') if simulating
      __debug_sim('Waiting for reviewer evaluation.')
      __debug_sim('REVIEWER must `approve!` or `reject!` to advance...')

    elsif submission.auto_approve # TODO: remove
      __debug_sim('[auto_review:  true]')
      __debug_sim('[auto_approve: true]')
      __debug_sim('SYSTEM review approves the submission.')

      approve! # NOTE: => :approved

    elsif submission.auto_reject # TODO: remove
      __debug_sim('[auto_review: true]')
      __debug_sim('[auto_reject: true]')
      __debug_sim('SYSTEM review rejects the submission.')

      reject! # NOTE: => :rejected

    else # TODO: remove
      __debug_sim('[auto_review:  true]')
      __debug_sim('[auto_approve: false]')
      __debug_sim('[auto_reject:  false]')
      __debug_sim('SYSTEM must `approve!` or `reject!` to advance...')

    end

    self
  end

  # Upon entering the :rejected state:
  #
  # The submission has been rejected.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_rejected_entry(state, event, *event_args)
    super

    __debug_sim('System notifies user of rejection.')
    __debug_sim('USER must `edit!` or `cancel!` to advance...')

    self
  end

  # Upon entering the :approved state:
  #
  # The submission has been approved.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_approved_entry(state, event, *event_args)
    super

    __debug_sim('SYSTEM notifies user of approval.')

    advance! # NOTE: => :staging
    self
  end

  # ===========================================================================
  # :section: UploadWorkflow::States overrides - Submission
  # ===========================================================================

  public

  # Upon entering the :staging state:
  #
  # The submission request (submitted file plus generated request form) has
  # been added to the staging area.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_staging_entry(state, event, *event_args)
    super

    # Determine whether this is destined for a member repository.
    if simulating
      __debug_sim("[emma_items: #{submission.emma_item}]")
      emma_items = submission.emma_item
    else
      emma_items = emma_item?(record)
    end

    unless simulating
      wf_finalize_submission(*event_args)
    end

    # TODO: simulation - remove
    if emma_items
      __debug_sim('SYSTEM determines this is an EMMA-native submission.')
    else
      __debug_sim('SYSTEM moves the submission into the repo staging area.')
    end

    # Automatically transition to the next state based on submission status.
    if emma_items
      index!   # NOTE: => :indexing
    else
      advance! # NOTE: => :unretrieved
    end
    self
  end

  # Upon entering the :unretrieved state:
  #
  # For a member repository submission, the record's workflow will remain in
  # this state until a separate action (external process or manual check via
  # the web interface) determines that the submission has been retrieved and
  # advances the state.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_unretrieved_entry(state, event, *event_args)
    super

    if simulating

      task = RetrievalTask

      unless event == :timeout
        __debug_sim("Start #{task} to check for the submission.")
        task.start
      end

      if task.check
        __debug_sim("The #{task} is checking...")
        timeout! # NOTE: => :unretrieved

      elsif task.success
        __debug_sim("The #{task} has detected the submission.")
        advance! # NOTE: => :retrieved

      else
        __debug_sim("The #{task} still has NOT detected the submission.")
        __debug_sim('SYSTEM notifies the user of submission status.')
        __debug_sim('SYSTEM notifies an agent of the member repository.')
        if task.restart
          __debug_sim("The #{task} is restarting.")
          timeout! # NOTE: => :unretrieved
        else
          __debug_sim("The #{task} is terminated.")
          fail!    # NOTE: => :failed
        end
      end

    end

    self
  end

  # Upon entering the :retrieved state:
  #
  # The submission request has been retrieved by the member repository and
  # removed from the staging area.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  # == Implementation Notes
  # This method automatically transitions to :indexing, but that's only because
  # there's no defined "signal" (from the perspective of the EMMA web service)
  # to indicate that
  #
  def on_retrieved_entry(state, event, *event_args)
    super

    __debug_sim('The submission has been received by the member repository.')
    __debug_sim('SYSTEM ensures the staging area is consistent.')

    advance! # NOTE: => :indexing
    self
  end

  # ===========================================================================
  # :section: UploadWorkflow::States overrides - Finalization
  # ===========================================================================

  public

  # Upon entering the :indexing state:
  #
  # For an EMMA-native submission, the item is being added to the index.
  #
  # For a member repository submission, the record's workflow will remain in
  # this state until a separate action (external process or manual check via
  # the web interface) determines that the entry has appeared in the index.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_indexing_entry(state, event, *event_args)
    super

    if simulating

      task = IndexTask

      unless event == :timeout
        __debug_sim("Start #{task} to check for the submission.")
        task.start
      end

      if task.check
        __debug_sim("The #{task} is checking...")
        timeout! # NOTE: => :indexing

      elsif task.success
        __debug_sim("The #{task} has detected the submission.")
        advance! # NOTE: => :indexed

      else
        __debug_sim("The #{task} still has NOT detected the submission.")
        __debug_sim('SYSTEM notifies the user of submission status.')
        __debug_sim('SYSTEM notifies an agent of the member repository.')
        if task.restart
          __debug_sim("The #{task} is restarting.")
          timeout! # NOTE: => :indexing
        else
          __debug_sim("The #{task} is terminated.")
          fail!    # NOTE: => :failed
        end
      end

    end

    unless simulating
      wf_index_update(*event_args)
      if emma_item?(record)
        if ready?
          advance! # NOTE: => :indexed
        else
          fail!    # NOTE: => :failed
        end
      end
    end

    self
  end

  # Upon entering the :indexed state:
  #
  # The submission is complete and present in the EMMA Unified Index.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_indexed_entry(state, event, *event_args)
    super

    __debug_sim('SYSTEM notifies the user that the submission is complete.')

    advance! # NOTE: => :completed
    self
  end

  # ===========================================================================
  # :section: UploadWorkflow::States overrides - Terminal
  # ===========================================================================

  public

  # Upon entering the :suspended state:
  #
  # The system is pausing the workflow; it may be resumable.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_suspended_entry(state, event, *event_args)
    super

    __debug_sim("[prev_state == #{prev_state.inspect}]")
    __debug_sim('Submission suspended until admin takes further action TBD.')
    __debug_sim('Associated data will persist indefinitely.')

    self
  end

  # Upon entering the :failed state:
  #
  # The system is terminating the workflow.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_failed_entry(state, event, *event_args)
    super

    __debug_sim("[prev_state == #{prev_state.inspect}]")
    __debug_sim('SYSTEM has terminated the workflow.')
    __debug_sim('Associated data will persist until this entry is pruned.')

    self
  end

  # Upon entering the :canceled state:
  #
  # The user is choosing to terminate the workflow.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_canceled_entry(state, event, *event_args)
    super

    __debug_sim('USER has terminated the workflow.')

    if simulating
      __debug_sim("[prev_state == #{prev_state.inspect}]")
      __debug_sim('Associated data will persist until this entry is pruned.')
    else
      __debug_sim('The submission record will be removed.')
    end

    unless simulating
      wf_cancel_submission(*event_args)
    end

    self
  end

  # Upon entering the :completed state:
  #
  # The user is choosing to terminate the workflow.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_completed_entry(state, event, *event_args)
    super

    __debug_sim("[prev_state == #{prev_state.inspect}]")
    __debug_sim('The submission has been completed successfully.')

    halt unless DEBUG_WORKFLOW
    self
  end

  # ===========================================================================
  # :section: UploadWorkflow::States overrides - Pseudo
  # ===========================================================================

  public

  # Upon entering the :resuming state:
  #
  # Pseudo-state indicating the previous workflow state.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_resuming_entry(state, event, *event_args)
    super
    persist_workflow_state(prev_state)
    __debug_entry(current_state)
    self
  end

  # Upon entering the :purged state:
  #
  # All data associated with the submission is being eliminated.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_purged_entry(state, event, *event_args)
    super

    __debug_sim('The submission entry is being purged.')

    __debug_sim('Shrine cache item is being removed from AWS S3.')
    # TODO: remove Shrine cache item from AWS S3.

    __debug_sim('Database entry is being removed.')
    # TODO: delete 'upload' table record, OR mark as purged:
    set_workflow_phase(:purge)

    halt
    self
  end

end

# =============================================================================
# :section: Base for individual-entry upload workflows
# =============================================================================

public

if UploadWorkflow::Single::SIMULATION
  require_relative '../../../lib/sim/models/upload_workflow/single'
end

# Base class for single-item upload workflows.
#
class UploadWorkflow::Single < UploadWorkflow

  include UploadWorkflow::Single::Events
  include UploadWorkflow::Single::States
  include UploadWorkflow::Single::Transitions

  # ===========================================================================
  # :section: Workflow::Base overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Upload, Hash, String, nil] data
  # @param [Hash]                      opt    Passed to #initialize_state
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def initialize(data, **opt)
    __debug("UPLOAD WF initialize UploadWorkflow::Single | opt[:start_state] = #{opt[:start_state].inspect} | opt[:init_event] = #{opt[:init_event].inspect} | data = #{data.class}")
    opt[:user] ||= (User.id_value(data[:user_id]) if data.is_a?(Hash))
    data.set_revert_data                          if data.is_a?(Upload)
    if (data &&= set_record(data))
      opt[:start_state] ||= get_workflow_state.presence&.to_sym || :starting
      data = nil
    end
    super(data, **opt)
  end

  # ===========================================================================
  # :section: Workflow::Base overrides
  # ===========================================================================

  protected

  # Set initial state.
  #
  # @param [Any, nil] data
  # @param [Hash]     opt
  #
  # @return [void]
  #
  def initialize_state(data, **opt)
    set_submission(data) if simulating # TODO: remove - testing
    super
  end

  # ===========================================================================
  # :section: UploadWorkflow overrides
  # ===========================================================================

  public

  # Indicate whether the workflow is dealing with the creation of a new EMMA
  # entry.
  #
  def new_submission?
    record ? record.new_submission? : super
  end

  # Indicate whether the workflow is dealing with the update/deletion of an
  # existing EMMA entry.
  #
  def existing_entry?
    record ? record.existing_entry? : super
  end

  # ===========================================================================
  # :section: Workflow overrides
  # ===========================================================================

  protected

  # Get the current state of the workflow item.
  #
  # @return [String]
  #
  def load_workflow_state
    get_workflow_state || super
  end

  # Set the current state of the workflow item.
  #
  # @param [Symbol, String] new_value
  #
  # @return [String]
  #
  def persist_workflow_state(new_value)
    set_workflow_state(new_value) || super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get the current real-time value of the record's workflow phase.
  #
  # @param [Upload, nil] rec          Default: `#record`.
  #
  # @return [Symbol, nil]
  #
  # @see Upload#get_phase
  #
  def get_workflow_phase(rec = nil)
    (rec || record)&.get_phase
  end

  # Set the current real-time value of the record's workflow phase.
  #
  # @param [Symbol, String, nil] new_value
  # @param [Upload, nil]         rec        Default: `#record`.
  #
  # @return [Symbol, nil]
  #
  # @see Upload#set_phase
  #
  #--
  # noinspection RubyMismatchedParameterType
  #++
  def set_workflow_phase(new_value = nil, rec = nil)
    (rec || record)&.set_phase(new_value)
  end

  # Get the current real-time value of the appropriate workflow state field.
  #
  # @param [Upload, nil] rec          Default: `#record`.
  #
  # @return [String]  If the field had a *nil* value it will come back as ''.
  # @return [nil]
  #
  # @see Upload#get_state
  #
  def get_workflow_state(rec = nil)
    (rec || record)&.get_state(workflow_column)&.to_s
  end

  # Set the current real-time value of the appropriate workflow state field.
  #
  # @param [Symbol, String, nil] new_value
  # @param [Upload, nil]         rec        Default: `#record`.
  #
  # @return [String]  If the field had a *nil* value it will come back as ''.
  # @return [nil]
  #
  # @see Upload#set_state
  #
  def set_workflow_state(new_value, rec = nil)
    (rec || record)&.set_state(new_value, workflow_column)&.to_s
  end

  # ===========================================================================
  # :section: Workflow::Base overrides - Class methods
  # ===========================================================================

  public

  # Generate a new instance of the appropriate workflow variant subclass.
  #
  # @param [String, Hash, Upload, nil] data
  # @param [Hash]                      opt
  #
  # @return [UploadWorkflow::Single]
  #
  def self.generate(data, **opt)
    data &&= data.is_a?(Upload) ? data : Upload.get_record(data)
    opt[:variant] ||= data&.phase
    opt[:variant] ||=
      if data.nil?
        :remove
      elsif data&.state&.to_sym == FINAL_STATE
        :edit
      else
        :create
      end
    # noinspection RubyMismatchedReturnType
    super(data, **opt)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Generate a new instance of the appropriate workflow variant subclass and
  # perform checking based on its status.
  #
  # @param [String, Hash, Upload, nil] data
  # @param [Hash]                      opt
  #
  # @option opt [String, Boolean] :html
  #
  # @return [UploadWorkflow::Single]
  #
  def self.check_status(data, **opt)
    generate(data, **opt.except(:html)).tap do |wf|
      wf.wf_check_status(opt)
    end
  end

end

__loading_end(__FILE__)
