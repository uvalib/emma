# app/jobs/attachment/destroy_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Remove a file.
#
# @note Currently unused
#
class Attachment::DestroyJob < ApplicationJob

  include ApplicationJob::Logging

  queue_as :background

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  # perform
  #
  # @param [Any] data
  #
  # @note Currently unused
  #
  def perform(data)
    __debug_job('START') { { data: item_inspect(data) } }
    attacher = FileUploader::Attacher.from_data(data)
    result   = attacher.destroy
    __debug_job('END') do
      { attacher: attacher, result: result }
        .transform_values { |v| item_inspect(v) }
    end

  rescue ActiveRecord::RecordNotFound => error
    Log.warn { "#{job_name}: skipped: #{error.message} [RecordNotFound]" }

  rescue => error
    Log.error { "#{job_name}: error: #{error.message} [#{error.class}]" }
  end

end

__loading_end(__FILE__)
