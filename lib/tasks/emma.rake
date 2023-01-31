# lib/tasks/emma.rake
#
# frozen_string_literal: true
# warn_indent:           true
#
# Maintenance tasks for the EMMA application.

require 'emma/rake'

# =============================================================================
# Tasks
# =============================================================================

namespace :emma do

  desc 'Ensure the application is set up properly.'
  task update: %w(emma:data:update)

  namespace :db do

    # desc 'Required prerequisites for tasks involving database records.'
    task prerequisites: %w(environment db:load_config)

  end

  namespace :model do

    # desc 'Required for tasks involving models/records.'
    task prerequisites: 'emma:db:prerequisites' do
      require_subdirs Rails.root.join('app/models')
    end

  end

end
