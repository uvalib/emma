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
  task prepare: %w(db:prepare emma_data:update)

end
