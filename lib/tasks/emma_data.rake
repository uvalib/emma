# lib/tasks/emma_data.rake
#
# frozen_string_literal: true
# warn_indent:           true
#
# Maintenance tasks for database table(s) involved with EMMA data.

require 'emma/rake'

# =============================================================================
# Tasks
# =============================================================================

namespace 'emma:data' do

  # Current version of EMMA Unified Index APIs.
  #
  # @type [String]
  #
  API_VERSION = INGEST_API_VERSION

  # ===========================================================================

  desc ['Migrate EMMA data to the latest API version and re-index.',
        "* Use '-- --quiet=false' to report non-activity",
        "* Use '-- --commit=false' to avoid updating the database",
        "* Use '-- --version=XXX' to test API version XXX data migration"]
  task update: :prerequisites do |_task, args|

    # Set parameters.
    version, commit, quiet = task_options(:version, :commit, :quiet, args)
    version = version.presence || API_VERSION
    commit  = !false?(commit) && (version == API_VERSION)
    quiet   = quiet ? !false?(quiet) : QUIET_DEFAULT

    # Execute subtasks if necessary.
    if (current = EmmaStatus.api_version&.value) && (version <= current)
      show "EMMA data already at API version '#{current}'." unless quiet # TODO: I18n
    elsif current
      show "Migrating EMMA data to API version '#{version}':" # TODO: I18n
      db_commit  = commit
      idx_commit = commit && production_deployment?
      subtask('emma:data:data_migrate', version: version, commit: db_commit)
      subtask('emma:data:reindex',      version: version, commit: idx_commit)
      EmmaStatus.api_version = version if db_commit
    else
      show "Skipping data migration for API version '#{current}'." unless quiet # TODO: I18n
    end

  end

  # ===========================================================================

  desc ["Migrate EMMA data for API #{API_VERSION}",
        "* Use '-- --time' for run time output",
        "* Use '-- --debug' for verbose data migration output",
        "* Use '-- --commit' to actually update the database",
        "* Use '-- --version=XXX' to test API version XXX data migration"]
  task data_migrate: :prerequisites do |_task, args|

    # Set parameters.
    version, commit, debug, time =
      task_options(:version, :commit, :debug, :time, args)
    version = version.presence || API_VERSION
    commit  = !commit.nil? && !false?(commit) && (version == API_VERSION)
    debug   = !debug.nil?  && !false?(debug)
    time    = (time || debug || VERBOSE_DEFAULT) && !false?(time)

    # Execute.
    save_start_time if time
    include ApiConcern
    result  = api_data_migration(version, dryrun: !commit, verbose: debug)

    # Output success message.
    count   = positive(result[:count]) || 0
    records = 'record'.pluralize(count)                 # TODO: I18n
    updated = commit ? 'updated' : 'would have changed' # TODO: I18n
    show if debug
    show "#{count} #{records} #{updated}."

    # Output time message.
    show elapsed_time if time

  end

  # ===========================================================================

  desc ['Re-index completed EMMA submissions',
         "* Use '-- --time' for run time output",
         "* Use '-- --debug' to list successful entries",
         "* Use '-- --atomic' to disallow failures within a batch",
         "* Use '-- --commit=false' to avoid sending to the Ingest API",
         "* Use '-- --batch=SIZE' to update the index in batches"]
  task reindex: :prerequisites do |_task, args|

    # Set parameters.
    batch, atomic, commit, debug, time =
      task_options(:batch, :atomic, :commit, :debug, :time, args)
    batch  = batch.presence
    atomic = !atomic.nil? && !false?(atomic)
    commit = !commit.nil? && !false?(commit)
    debug  = !debug.nil?  && !false?(debug)
    time   = (time || debug || VERBOSE_DEFAULT) && !false?(time)

    # Execute.
    save_start_time if time
    include UploadConcern
    options = { size: batch, atomic: atomic, dryrun: !commit }
    result, failed = reindex_submissions(**options)

    # Output success message(s).
    count   = positive(result.size - failed.size) || 0
    entries = 'submission'.pluralize(count)                        # TODO: I18n
    updated = commit ? 're-indexed' : 'would have been re-indexed' # TODO: I18n
    message = "#{count} #{entries} #{updated}"
    if debug && count.positive?
      show "#{message}: #{result.inspect}"
      show if failed.present?
    else
      show "#{message}."
    end

    # Output failure message(s).
    if failed.present?
      count   = atomic ? 'all' : failed.size       # TODO: I18n
      entries = 'submission'.pluralize(count.to_i) # TODO: I18n
      message = "#{count} #{entries} failed"       # TODO: I18n
      show "#{message}:", failed
    end

    # Output time message.
    show elapsed_time if time

  end

  # ===========================================================================

  # desc 'Required prerequisites for tasks in this namespace.'
  task prerequisites: 'emma:db:prerequisites'

end

# desc 'An alias for "rake emma:data:data_migrate".'
task 'emma:api_migrate' => 'emma:data:data_migrate'

# desc 'An alias for "rake emma:data:reindex".'
task 'emma:bulk_reindex' => 'emma:data:reindex'
