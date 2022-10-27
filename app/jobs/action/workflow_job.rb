# app/jobs/action/workflow_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

#require 'models/action'

class Action::WorkflowJob < Model::WorkflowJob

  include ApplicationJob::Logging

=begin
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
    self.arguments.first.try(:bulk?) ? :bulk : :normal
  end
=end

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

=begin
  # Run the command(s) specified by the Action. # TODO: needed?
  #
  # @param [Action] action
  # @param [Hash]   opt
  # @param [Proc]   block
  #
  def perform(action, **opt, &block)
    __debug_job('START') { { action: action } }
    result = block.call(action, **opt) # TODO: ...
    __debug_job('END') { { result: result } }

  rescue ActiveRecord::RecordNotFound => error
    Log.warn { "#{job_name}: skipped: #{error.message} [RecordNotFound]" }
    raise error

  rescue => error
    Log.error { "#{job_name}: error: #{error.message} [#{error.class}]" }
    raise error
  end
=end

  # Run the command(s) specified by the Action. # TODO: needed?
  #
  def perform(*args)
    __debug_items(binding)
    super
  end

end

__loading_end(__FILE__)
