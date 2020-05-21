# app/jobs/attachment/destroy_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Remove a file.
#
class Attachment::DestroyJob < ApplicationJob

  include Emma::Debug

  # perform
  #
  # @param [*] data
  #
  def perform(data)
    __debug_args(binding)
    attacher = FileUploader::Attacher.from_data(data)
    __debug("JOB #{__method__} | attacher = #{attacher.inspect}")
    attacher.destroy
  rescue ActiveRecord::RecordNotFound => e
    Log.warn { "JOB #{__method__}: skipped: #{e.message} [RecordNotFound]" }
  rescue => e
    Log.error { "JOB #{__method__}: error: #{e.message} [#{e.class}]" }
  end

end

__loading_end(__FILE__)
