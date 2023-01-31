# app/jobs/model/workflow_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class Model::WorkflowJob < ApplicationJob

  include ApplicationJob::Logging

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    extend ActiveJob::Core
    # :nocov:
  end

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
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  PERFORM_OPTS = %i[receiver meth callback].freeze

  # Run the command(s) specified by the Action.
  #
  # @param [Array] args
  #
  # @return [void]
  #
  #--
  # == Variations
  #++
  #
  # @overload perform(model, meth, callback, **opt)
  #   @param [Model]            model
  #   @param [Symbol]           meth
  #   @param [AsyncCallback]    callback
  #   @param [Hash]             opt
  #   @option opt [Model, nil]    :from       Passed to *meth*.
  #   @option opt [AsyncCallback] :callback   Ignored.
  #
  # @overload perform(model, meth, **opt)
  #   @param [Model]            model
  #   @param [Symbol]           meth
  #   @param [Hash]             opt
  #   @option opt [Model, nil]    :from       Passed to *meth*.
  #   @option opt [AsyncCallback] :callback   Optional.
  #
  # @overload perform(model, **opt)
  #   @param [Model]            model
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

    opt, meth_opt = partition_hash(args.extract_options!, *PERFORM_OPTS)
    model    = args.shift || opt[:receiver] # TODO: :receiver?
    meth     = args.shift || opt[:meth]
    callback = args.shift || opt[:callback]

    warn = fail = nil
    if model && meth
      __debug_job('START') do
        { model: model, meth: meth, callback: callback, from: meth_opt[:from] }
          .transform_values { |v| item_inspect(v) }
      end
      __output "..................... perform | BEFORE #{model.class}.#{meth}(#{meth_opt.inspect}) | callback = #{callback.inspect}"
      result = model.send(meth, **meth_opt)
      __output "..................... perform | AFTER  #{model.class}.#{meth}(#{meth_opt.inspect}) | callback = #{callback.inspect}"
      perform_callback(callback, from: model) if callback && result
      __debug_job('END') do
        { result: item_inspect(result) }
      end
    elsif callback
      warn = 'no model/method; only callback'
    elsif model && !meth
      fail = "missing method for model #{model.inspect}"
    elsif meth && !model
      fail = "missing model for method #{meth.inspect}"
    else
      fail = 'missing model/method'
    end
    Log.info { "#{job_name}: #{warn}" } if warn
    raise fail if fail

  rescue ActiveRecord::RecordNotFound => error
    Log.warn { "#{job_name}: skipped: #{error.message} [RecordNotFound]" }
    raise error

  rescue => error
    Log.error { "#{job_name}: error: #{error.message} [#{error.class}]" }
    raise error
  end
    .tap { |meth| ruby2_keywords(meth) }

end

__loading_end(__FILE__)
