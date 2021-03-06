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

  include Emma::Debug

  # perform
  #
  # @param [Upload] record
  # @param [Symbol] name              Should be :file.
  # @param [*]      data              :file_data
  #
  # @note Currently unused
  #
  def perform(record, name, data)
    __debug_items(binding)
    attacher =
      FileUploader::Attacher.retrieve(model: record, name: name, file: data)
    __debug_line("JOB #{__method__}") { { attacher: attacher } }
    # attacher.create_derivatives if record.is_a?(Album)
    attacher.atomic_promote
  rescue Shrine::AttachmentChanged => e
    Log.info { "JOB #{__method__}: skipped: #{e.message} [AttachmentChanged]" }
  rescue ActiveRecord::RecordNotFound => err
    Log.warn { "JOB #{__method__}: skipped: #{err.message} [RecordNotFound]" }
  rescue => err
    Log.error { "JOB #{__method__}: error: #{err.message} [#{err.class}]" }
  end

end

__loading_end(__FILE__)
