# app/jobs/attachment/destroy_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Remove a file.
#
# @note Currently unused.
# :nocov:
class Attachment::DestroyJob < ApplicationJob

  include ApplicationJob::Logging

  queue_as :background

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  # perform
  #
  # @param [any, nil] data
  #
  # @return [void]
  #
  def perform(data)
    __debug_job('START') { { data: item_inspect(data) } }
    attacher = FileUploader::Attacher.from_data(data)
    result   = attacher.destroy
    __debug_job('END') do
      { attacher: attacher, result: result }
        .transform_values { item_inspect(_1) }
    end

  rescue ActiveRecord::RecordNotFound => error
    Log.warn { "#{job_tag}: skipped: #{error.message} [RecordNotFound]" }

  rescue => error
    Log.error { "#{job_tag}: error: #{error.message} [#{error.class}]" }
  end

end
# :nocov:

__loading_end(__FILE__)
