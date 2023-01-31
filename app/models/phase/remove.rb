# app/models/phase/remove.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Entry removal workflow tracking record.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.phase.remove*
#
# @!method started?
# @!method deindexing?
# @!method dequeuing?
# @!method unstoring?
# @!method removing?
# @!method removed?
# @!method canceling?
# @!method canceled?
# @!method aborted?
#
# @!method started!
# @!method deindexing!
# @!method dequeuing!
# @!method unstoring!
# @!method removing!
# @!method removed!
# @!method canceling!
# @!method canceled!
# @!method aborted!
#
class Phase::Remove < Phase::BulkPart

  include Record::Sti::Leaf
  include Record::Steppable

  # @private
  CLASS = self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Remove the entry from the index.
  #
  # @param [ActionDispatch::Request, Hash, nil] request
  # @param [Hash] opt                 Passed to Action::UnIndex#deindex!
  #
  # @raise [ActiveRecord::RecordInvalid]    Action record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Action record creation halted.
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def deindex!(request, **opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:deindexing, **opt) or return
    set_callback!(opt, :deindex_cb)
    generate_action(:UnIndex).job_run(:deindex!, request, **opt)
  end

  # Method called from the action launched by #deindex!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def deindex_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    if action.failed?
      aborted!
      false
    else
      run_callback(**opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Remove the submission from its queue.
  #
  # @param [ActionDispatch::Request, Hash, nil] request
  # @param [Hash] opt                 Passed to Action::UnQueue#unsubmit!
  #
  # @raise [ActiveRecord::RecordInvalid]    Action record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Action record creation halted.
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def unsubmit!(request, **opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:dequeuing, **opt) or return
    set_callback!(opt, :unsubmit_cb)
    generate_action(:UnQueue).job_run(:unsubmit!, request, **opt)
  end

  # Method called from the action launched by #unsubmit!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def unsubmit_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    if action.failed?
      aborted!
      false
    else
      run_callback(**opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Remove the uploaded file associated with this item.
  #
  # @param [ActionDispatch::Request, Hash, nil] request
  # @param [Hash] opt                 Passed to Action::UnStore#unstore!
  #
  # @raise [ActiveRecord::RecordInvalid]    Action record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Action record creation halted.
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def unstore!(request, **opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:unstoring, **opt) or return
    set_callback!(opt, :unstore_cb)
    generate_action(:UnStore).job_run(:unstore!, request, **opt)
  end

  # Method called from the action launched by #unstore!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def unstore_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    if action.failed?
      aborted!
      false
    else
      run_callback(**opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Remove the item from the database.
  #
  # @param [ActionDispatch::Request, Hash, nil] request
  # @param [Hash] opt                 Passed to Action::UnRecord#remove!
  #
  # @raise [ActiveRecord::RecordInvalid]    Action record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Action record creation halted.
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def remove!(request, **opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:removing, **opt) or return
    set_callback!(opt, :remove_cb)
    generate_action(:UnRecord).job_run(:remove!, request, **opt)
  end

  # Method called from the action launched by #remove!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def remove_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    if action.failed?
      aborted!
      false
    else
      run_callback(**opt)
    end
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the type of the Model instance.
  #
  # @param [Phase] phase
  # @param [Hash]  opt
  #
  # @return [String]
  #
  def self.describe_type(phase, **opt)
    "is being removed by #{phase.user}" # TODO: I18n
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  validate_state_table if sanity_check?

end

__loading_end(__FILE__)
