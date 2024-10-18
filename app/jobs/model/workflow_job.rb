# app/jobs/model/workflow_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class Model::WorkflowJob < ApplicationJob

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    extend ActiveJob::Core
  end
  # :nocov:

  # @private
  CLASS = self

  # ===========================================================================
  # :section: ActiveJob properties
  # ===========================================================================

  queue_as do
    __output ">>> #{CLASS} queue_as | args = #{arguments_inspect(self)}"
    arguments.first.try(:bulk?) ? :bulk : :normal
  end

  # ===========================================================================
  # :section: ApplicationJob overrides
  # ===========================================================================

  public

  def initialize(*args, **opt)
    cb     = opt.delete(:callback)
    cb_opt = opt.slice(:cb_receiver, :cb_method).presence
    job_warn { "ignoring #{cb_opt.inspect}" } if cb && cb_opt
    opt[:callback] = AsyncCallback.new(cb)    if (cb ||= cb_opt)
    opt.except!(*cb_opt.keys)                 if cb_opt
    super
  end

  # ===========================================================================
  # :section: Application::Logging overrides
  # ===========================================================================

  protected

  def item_inspect(v)
    v.is_a?(Model::AsyncCallback) ? "#{v.class} #{hash_inspect(v)}" : super
  end

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  PERFORM_OPT = %i[receiver meth callback].freeze

  # Run the command(s) specified by the model.
  #
  # @param [Array] args
  #
  # @return [void]
  #
  #--
  # === Variations
  #++
  #
  # @overload perform(model, meth, callback, **opt)
  #   @param [Model]         model
  #   @param [Symbol]        meth
  #   @param [AsyncCallback] callback
  #   @param [Hash]          opt
  #   @option opt [Model, nil]    :from       Passed to *meth*.
  #   @option opt [AsyncCallback] :callback   Ignored.
  #
  # @overload perform(model, meth, **opt)
  #   @param [Model]         model
  #   @param [Symbol]        meth
  #   @param [Hash]          opt
  #   @option opt [Model, nil]    :from       Passed to *meth*.
  #   @option opt [AsyncCallback] :callback   Optional.
  #
  # @overload perform(model, **opt)
  #   @param [Model]         model
  #   @option opt [Symbol]        :meth
  #   @option opt [Model, nil]    :from       Passed to *meth*.
  #   @option opt [AsyncCallback] :callback   Optional.
  #
  # @overload perform(**opt)
  #   @option opt [Model]         :receiver # TODO: ?
  #   @option opt [Symbol]        :meth
  #   @option opt [Model, nil]    :from       Passed to *meth*.
  #   @option opt [AsyncCallback] :callback   Optional.
  #
  def perform(*args)
    __debug_items(binding)

    opt   = args.extract_options!.dup
    local = opt.extract!(*PERFORM_OPT)
    model = args.shift || local[:receiver] # TODO: :receiver?
    meth  = args.shift || local[:meth]
    cb    = args.shift || local[:callback]

    warn = fail = nil
    if model && meth
      __debug_job('START') do
        { model: model, meth: meth, callback: cb, from: opt[:from] }
          .transform_values { item_inspect(_1) }
      end
      __output "..................... perform | BEFORE #{model.class}.#{meth}(#{opt.inspect}) | callback = #{cb.inspect}"
      result = model.send(meth, **opt)
      __output "..................... perform | AFTER  #{model.class}.#{meth}(#{opt.inspect}) | callback = #{cb.inspect}"
      perform_callback(cb, from: model) if cb && result
      __debug_job('END') do
        { result: item_inspect(result) }
      end
    elsif cb
      warn = 'no model/method; only callback'
    elsif model && !meth
      fail = "missing method for model #{model.inspect}"
    elsif meth && !model
      fail = "missing model for method #{meth.inspect}"
    else
      fail = 'missing model/method'
    end
    Log.info { "#{job_tag}: #{warn}" } if warn
    raise fail if fail

  rescue ActiveRecord::RecordNotFound => error
    Log.warn { "#{job_tag}: skipped: #{error.message} [RecordNotFound]" }
    raise error

  rescue => error
    Log.error { "#{job_tag}: error: #{error.message} [#{error.class}]" }
    raise error
  end
    .tap { ruby2_keywords(_1) }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Called from #perform to initiate a callback if one was supplied via the job
  # arguments.
  #
  # @param [AsyncCallback, nil] callback
  # @param [Hash]               opt       Passed to #cb_schedule.
  #
  # @option opt [AsyncCallback] :callback
  #
  # @return [void]
  #
  def perform_callback(callback, **opt)
    job_warn { 'ignoring blank callback' } unless callback
    callback&.cb_schedule(**opt)
  end

end

__loading_end(__FILE__)
