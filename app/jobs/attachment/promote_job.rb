# app/jobs/attachment/promote_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Promote a file from :cache to :store.
#
# @note Currently unused
#
class Attachment::PromoteJob < ApplicationJob

  include ApplicationJob::Logging

  queue_as :background

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  # perform
  #
  # @param [Model]  record
  # @param [Symbol] name              Should be :file.
  # @param [*]      data              :file_data
  #
  # @note Currently unused
  #
  def perform(record, name, data)
    __debug_job('START') do
      { name: name, data: data, record: record }
        .transform_values { |v| item_inspect(v) }
    end
    attacher =
      FileUploader::Attacher.retrieve(model: record, name: name, file: data)
    # attacher.create_derivatives if record.is_a?(Album)
    result = attacher.atomic_promote
    __debug_job('END') do
      { attacher: attacher, result: result }
        .transform_values { |v| item_inspect(v) }
    end

  rescue Shrine::AttachmentChanged => error
    Log.info { "#{job_name}: skipped: #{error.message} [AttachmentChanged]" }

  rescue ActiveRecord::RecordNotFound => error
    Log.warn { "#{job_name}: skipped: #{error.message} [RecordNotFound]" }

  rescue => error
    Log.error { "#{job_name}: error: #{error.message} [#{error.class}]" }
  end

end

__loading_end(__FILE__)
