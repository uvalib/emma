#
# app/jobs/session_cleanup_job.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'rake'

class SessionCleanupJob < ApplicationJob
  queue_as :background
  require 'rake'
  Emma::Application.load_tasks

  def perform(*args, **opt)
    Rake::Task['db:sessions:trim'].invoke
  end
end

__loading_end(__FILE__)
