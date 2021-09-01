# app/models/action/store.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Manage execution of a Shrine file upload to AWS S3 storage.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.action.store*
#
# @!method started?
# @!method uploading?
# @!method uploaded?
# @!method promoting?
# @!method completed?
# @!method canceled?
# @!method aborted?
#
# @!method started!
# @!method uploading!
# @!method uploaded!
# @!method promoting!
# @!method completed!
# @!method canceled!
# @!method aborted!
#
class Action::Store < Action::BulkPart

  include Record::Sti::Leaf
  include Record::Steppable
  include Record::Uploadable

  # @private
  CLASS = self

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Update database fields, including the structured contents of the :emma_data
  # field.
  #
  # @param [Hash, ActionController::Parameters, Model, nil] attr
  # @param [Hash, nil]                                      opt
  #
  # @return [void]
  #
  # @see Record::EmmaData#EMMA_DATA_KEYS
  #
  def assign_attributes(attr, opt = nil)
    __debug_items(binding)
    data, attr = partition_hash(attr, *EMMA_DATA_KEYS)
    attr = attribute_options(attr, opt)
    attr[:emma_data] = generate_emma_data(data, attr)
    super(attr, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Receive from the client and store to AWS S3 :cache via Shrine.
  #
  # @param [ActionDispatch::Request, Hash, nil] request
  # @param [Hash]                               opt   To callback except:
  #
  # @option opt [Boolean] :update_record  If *false* caller will update record.
  # @option opt [Boolean] :auto_retry     If *true* automatically retry.
  # @option opt [*]       :env            From *request* by default.
  # @option opt [Symbol]  :meth           Name of caller (for logging).
  #
  # @return [(Integer, Hash{String=>*}, Array<String>)]
  #
  # @see Record::Uploadable#upload_file
  #
  # == Usage Notes
  # If a callback is supplied via *opt*, it is executed synchronously.
  #
  def upload!(request, **opt)                                                   # NOTE: from UploadWorkflow::Single::Actions#wf_upload_file
    __debug_step(binding)
    opt, cb_opt = partition_hash(opt, :meth, :env, :auto_retry, :update_record)
    opt[:meth] ||= __method__
    stat = hdrs = body = nil
    env  = opt.delete(:env)
    env  = request || env
    env  = env.env if env.is_a?(ActionDispatch::Request)
    transition_sequence(**opt) {{
      uploading: ->(*) { stat, hdrs, body = upload_file(env: env) }
    }}
    auto_retry    = opt.key?(:auto_retry)    ? opt[:auto_retry]    : false
    update_record = opt.key?(:update_record) ? opt[:update_record] : true
    problem =
      if aborted?
        '' # Internal values already set in #execute_step.
      elsif stat.nil?
        'missing request env data'
      elsif stat != 200
        'invalid file'
      elsif (data = json_parse(body&.first)).blank?
        'invalid response body'
      else
        # noinspection RubyNilAnalysis
        self.emma_data = data.delete(:emma_data)
        self.file_data = data
        $stderr.puts "++++++++++++++++++++++++ #{CLASS}.upload! | action.file_data #{file_data.class} | action.emma_data #{emma_data.class}"
        'empty file_data' if file_data.blank?
      end
    if problem.nil?
      self.condition = :succeeded
      self.state     = :uploaded
    elsif problem.present?
      self.condition = :failed
      self.state     = auto_retry ? :started : :aborted
      self.command   = :retry if auto_retry
      set_exec_report(problem)
    end
    save if update_record
    if retry?
      $stderr.puts "++++++++++++++++++++++++ #{CLASS}.upload! | retry? = #{retry?.inspect}"
      nil # TODO: ...what happens here?
    else
      $stderr.puts "++++++++++++++++++++++++ #{CLASS}.upload! | run_callback opt = #{cb_opt.inspect}"
      cb_opt[:meth] = opt[:meth]
      run_callback(**cb_opt)
      $stderr.puts "++++++++++++++++++++++++ #{CLASS}.upload! | action.file_data #{file_data.class} | BAD | after run_callback" if file_data.is_a?(String)
    end
    return stat, hdrs, body
  end

  # Move the uploaded file associated with this item from :cache to :store.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  def promote!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_sequence(**opt) {{
      promoting: ->(*) { promote_file },
      completed: true
    }} or return false
    $stderr.puts "++++++++++++++++++++++++ #{CLASS}.promote! | action.file_data #{file_data.class} | BAD | after promote_file" if file_data.is_a?(String)
    run_callback(**opt)
      .tap { $stderr.puts "++++++++++++++++++++++++ #{CLASS}.promote! | action.file_data #{file_data.class} | BAD | after run_callback" if file_data.is_a?(String) }
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the type of the Model instance.
  #
  # @return [String]
  #
  def self.describe_type(*)
    'uploading' # TODO: I18n
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
