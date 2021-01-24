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

  include Emma::Debug

  # perform
  #
  # @param [*] data
  #
  # @note Currently unused
  #
  def perform(data)
    __debug_args(binding)
    attacher = FileUploader::Attacher.from_data(data)
    __debug("JOB #{__method__} | attacher = #{attacher.inspect}")
    attacher.destroy
  rescue ActiveRecord::RecordNotFound => err
    Log.warn { "JOB #{__method__}: skipped: #{err.message} [RecordNotFound]" }
  rescue => err
    Log.error { "JOB #{__method__}: error: #{err.message} [#{err.class}]" }
  end

end

__loading_end(__FILE__)
