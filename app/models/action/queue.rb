# app/models/action/queue.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Control record tracking queueing submission to an AWS S3 bucket.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.action.queue*
#
# @!method started?
# @!method submitting?
# @!method unretrieved?
# @!method retrieved?
# @!method canceled?
# @!method aborted?
#
# @!method started!
# @!method submitting!
# @!method unretrieved!
# @!method retrieved!
# @!method canceled!
# @!method aborted!
#
class Action::Queue < Action::BulkPart

  include Record::Sti::Leaf
  include Record::Steppable
  include Record::Uploadable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Enqueue the submission package to the appropriate AWS S3 bucket.
  #
  # @param [String] sid               Submission ID.
  # @param [Hash]   opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean, nil]
  #
  def submit!(sid:, **opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    self.submission_id = sid
    transition_sequence(**opt) {{
      submitting:  ->(*, **) { member_repository_action(:creation_request) },
      unretrieved: true
    }} and run_callback(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the item has been removed from the AWS S3 bucket.
  #
  # @param [String, nil] sid          Default: `#sid_value`
  #
  def not_in_queue?(sid = nil, **opt)
    sid  = sid_value(sid || opt.presence)
    repo = repository_value(opt.presence)
    aws_api.list_records(sid, repo: repo).values_at(sid).flatten.blank?
  end

  # check_retrieved # TODO: I18n
  #
  # @param [String, nil] sid          Default: `#sid_value`
  # @param [Boolean]     advance      If *false* do not advance workflow state.
  # @param [Hash]        opt
  #
  # @return [String]
  #
  def check_retrieved(sid = nil, advance: true, **opt)                          # NOTE: from UploadWorkflow::Single::Actions#wf_check_retrieved
    sid  = sid_value(sid || opt.presence)
    repo = repository_value(opt.presence)
    sub  = "submission #{sid.inspect}"
    sub  = "#{repository_name(repo)} #{sub}" unless emma_native?
    done = not_in_queue?(sid)
    retrieved! if done && !false?(advance)
    if done
      "the index service is now processing #{sub}"
    else
      "#{sub} has not yet been included in the index"
    end
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the type of the Model instance.
  #
  # @return [String]
  #
  def self.describe_type(...)
    'submitting to %{repo}' # TODO: I18n
  end

  # A textual description of the status of the Action instance.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [String]
  #
  def self.describe_status(action, **opt)
    opt[:note]   = action.state_note
    opt[:state]  = (action.state_description unless opt[:note])
    opt[:note] ||= describe_type(action, **opt)
    super(action, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  validate_state_table unless application_deployed?

end

__loading_end(__FILE__)
