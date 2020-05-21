# app/jobs/attachment/promote_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Promote a file from :cache to :store.
#
class Attachment::PromoteJob < ApplicationJob

  include Emma::Debug

  # perform
  #
  # @param [Upload] record
  # @param [Symbol] name              Should be :file.
  # @param [*]      data              :file_data
  #
  def perform(record, name, data)
    __debug_args(binding)
    attacher =
      FileUploader::Attacher.retrieve(model: record, name: name, file: data)
    __debug("JOB #{__method__} | attacher = #{attacher.inspect}")
    # attacher.create_derivatives if record.is_a?(Album)
    attacher.atomic_promote
  rescue Shrine::AttachmentChanged => e
    Log.info { "JOB #{__method__}: skipped: #{e.message} [AttachmentChanged]" }
  rescue ActiveRecord::RecordNotFound => e
    Log.warn { "JOB #{__method__}: skipped: #{e.message} [RecordNotFound]" }
  rescue => e
    Log.error { "JOB #{__method__}: error: #{e.message} [#{e.class}]" }
  end

end

__loading_end(__FILE__)
