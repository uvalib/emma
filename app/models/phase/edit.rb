# app/models/phase/edit.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Entry modification workflow tracking record.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.phase.edit*
#
# @!method started?
# @!method uploading?
# @!method replacing?
# @!method indexing?
# @!method indexed?
# @!method submitting?
# @!method submitted?
# @!method canceling?
# @!method canceled?
# @!method aborted?
#
# @!method started!
# @!method uploading!
# @!method replacing!
# @!method indexing!
# @!method indexed!
# @!method submitting!
# @!method submitted!
# @!method canceling!
# @!method canceled!
# @!method aborted!
#
class Phase::Edit < Phase::BulkPart

  include Record::Sti::Leaf
  include Record::EmmaData
  include Record::Steppable
  include Record::Uploadable

  # @private
  CLASS = self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Upload file to AWS S3 Shrine :cache.
  #
  # @param [ActionDispatch::Request, Hash, nil] request
  # @param [Hash] opt                 Passed to Action::Store#update! except:
  #
  # @option opt [Boolean] :async      Always ignored.
  #
  # @raise [ActiveRecord::RecordInvalid]    Action record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Action record creation halted.
  #
  # @return [(Integer, Hash{String=>Any}, Array<String>)]
  #
  # @see Action::Store#upload!
  #
  # == Usage Notes
  # Always performed synchronously.
  #
  def upload!(request, **opt)
    $stderr.puts "++++++++++++++++++++++++ upload! | #{self.class} |"
    __debug_items(binding)
    opt[:meth] ||= __method__
    transition_to(:uploading, **opt) or return []
    set_callback!(opt, :upload_cb)
    generate_action(:Store).upload!(request, **opt)
      .tap { $stderr.puts "++++++++++++++++++++++++ upload! | #{self.class} | phase.file_data #{file_data.class} | BAD after action.upload!" if file_data.is_a?(String) }
  end

  # Method called from the action launched by #upload!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  # == Usage Notes
  # Will be performed synchronously by Action::Store#upload!.
  #
  def upload_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    $stderr.puts "++++++++++++++++++++++++ upload_cb | #{self.class} | from #{action.class} | action.file_data #{action.file_data.class} | action.emma_data #{action.emma_data.class}"
    if action.failed?
      aborted!
      false
    else
      self.file_data = safe_json_parse(action.file_data, symbolize_keys: false)
      self.emma_data = safe_json_parse(action.emma_data, symbolize_keys: false)
      $stderr.puts "++++++++++++++++++++++++ upload_cb | #{self.class} | from #{action.class} | phase.file_data #{file_data.class} | phase.emma_data #{emma_data.class}"
      save
      $stderr.puts "++++++++++++++++++++++++ upload_cb | #{self.class} | from #{action.class} | phase.file_data #{file_data.class} | BAD after save" if file_data.is_a?(String)
      run_callback(**opt)
    end
      .tap { $stderr.puts "++++++++++++++++++++++++ upload_cb | #{self.class} | from #{action.class} | phase.file_data #{file_data.class} | BAD after run_callback" if file_data.is_a?(String) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Move uploaded file from Shrine :cache to Shrine :store.
  #
  # @param [Hash] opt                 Passed to Action::Store#promote!
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def promote!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:replacing, **opt) or return
    set_callback!(opt, :promote_cb)
    action = actions.where(type: :Store).order(:updated_at).last
    raise "no Action found for #{CLASS}::#{__method__}" unless action
    action.job_run(:promote!, **opt)
  end

  # Method called from the action launched by #promote!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def promote_cb(action = nil, **opt)
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

  # Create an index entry for this item.
  #
  # @param [Hash] opt                 Passed to Action::Index#index!
  #
  # @raise [ActiveRecord::RecordInvalid]    Action record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Action record creation halted.
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def index!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:indexing, **opt) or return
    set_callback!(opt, :index_cb)
    generate_action(:Index).job_run(:index!, **opt)
  end

  # Method called from the action launched by #index!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def index_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    if action.failed?
      aborted!
      false
    else
      indexed!
      run_callback(**opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Send a submission package to a member repository.
  #
  # @param [Hash] opt                 Passed to Action::Queue#submit!
  #
  # @raise [ActiveRecord::RecordInvalid]    Action record creation failed.
  # @raise [ActiveRecord::RecordNotSaved]   Action record creation halted.
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def submit!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:submitting, **opt) or return
    set_callback!(opt, :submit_cb)
    generate_action(:Queue).job_run(:submit!, **opt.merge!(sid: submission_id))
  end

  # Method called from the action launched by #submit!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def submit_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    if action.failed?
      aborted!
      false
    else
      submitted!
      run_callback(**opt)
    end
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the type of the Model instance.
  #
  # @param [Phash] phase
  # @param [Hash]  opt
  #
  # @return [String]
  #
  def self.describe_type(phase, **opt)
    "is being modified by #{phase.user}" # TODO: I18n
  end

  # A textual description of the status of the given Phase instance.
  #
  # @param [Phase] phase
  # @param [Hash]  opt
  #
  # @return [String]
  #
  def self.describe_status(phase, **opt)
    opt[:note] ||= describe_type(phase, **opt)
    super(phase, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  validate_state_table unless application_deployed?

end

__loading_end(__FILE__)
