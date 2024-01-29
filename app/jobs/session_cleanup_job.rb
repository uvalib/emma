#
# app/jobs/session_cleanup_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class SessionCleanupJob < ApplicationJob

  queue_as :background

  def initialize(*args, **opt)
    Emma::Application.load_tasks
    super
  end

  def perform(*)
    Rake::Task['db:sessions:trim'].invoke
  end

end

__loading_end(__FILE__)
