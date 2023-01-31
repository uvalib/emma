# app/models/concerns/job_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# This is a mixin for record classes related to jobs.
#
module JobMethods

  extend ActiveSupport::Concern

  include Emma::Common

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActiveRecord::QueryMethods
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The database column checked against the time of last reboot to determine
  # whether the record is defunct.
  #
  # @return [Symbol]
  #
  def activity_column
    :finished_at
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Select the records for jobs that have not yet completed.
  #
  # @return [ActiveRecord::Relation]
  #
  # @note How does this relate to GoodJob::Job#finished
  #
  def incomplete
    self_class.where(activity_column => nil)
  end

  # Indicate how many jobs have not yet completed.
  #
  # @return [Integer]
  #
  def incomplete_count
    incomplete.count
  end

  # Select the records for jobs that have not yet completed.
  #
  # @param [String,Symbol,Hash] sort_order
  #
  # @return [ActiveRecord::Relation]
  #
  def incomplete_list(sort_order: { created_at: :desc })
    incomplete.order(sort_order)
  end

  # Remove the records for jobs that have not yet completed.
  #
  # @return [Integer]
  #
  def incomplete_delete
    incomplete.delete_all
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Select the records that have not been updated since the last reboot.
  #
  # @return [ActiveRecord::Relation]
  #
  # @note How does this relate to GoodJob::Job#finished_before
  #
  def outdated
    self_class.where(activity_column => ..outdated_last_reboot)
  end

  # Indicate how many records have not been updated since the last reboot.
  #
  # @return [Integer]
  #
  def outdated_count
    outdated.count
  end

  # Select the records that have not been updated since the last reboot.
  #
  # @param [String,Symbol,Hash] sort_order
  #
  # @return [ActiveRecord::Relation]
  #
  def outdated_list(sort_order: { created_at: :desc })
    outdated.order(sort_order)
  end

  # Remove the records that have not been updated since the last reboot.
  #
  # @return [Integer]
  #
  def outdated_delete
    outdated.delete_all
  end

  # Times before this are considered "outdated".
  #
  # NOTE: This currently is only correct from within the Rails application.
  #   For Rake tasks it's not because there needs to be a mechanism for
  #   persisting the last boot time.
  #
  # @return [Time]
  #
  def outdated_last_reboot
    BOOT_TIME
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Select only the 'good_jobs' records involving this client request.
  #
  # @param [String] stream
  #
  # @return [ActiveRecord::Relation]
  #
  def for(stream)
    # noinspection RubyMismatchedReturnType
    where(%Q(#{stream_name} = '#{stream}'))
  end

  # SQL fragment representing the lookup service in the data.
  #
  # In context, this will yield a SQL string value.
  #
  # @return [String]
  #
  def service
    %Q(#{job_service}->>'value')
  end

  # SQL fragment representing the stream name in the data.
  #
  # In context, this will yield a SQL string value.
  #
  # @return [String]
  #
  def stream_name
    %Q(#{job_options}->>'stream_name')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # SQL fragment representing the items being looked up.
  #
  # In context, this will yield a SQL JSON object.
  #
  # @return [String]
  #
  def job_service
    job_arguments(0)
  end

  # SQL fragment representing the items being looked up.
  #
  # In context, this will yield a SQL JSON object.
  #
  # @return [String]
  #
  def job_items
    job_arguments(1)
  end

  # SQL fragment representing the ActiveJob options for the record.
  #
  # In context, this will yield a SQL JSON object.
  #
  # @return [String]
  #
  def job_options
    job_arguments(-1)
  end

  # SQL fragment extracting ActiveJob arguments for the record or selecting a
  # specific argument value.
  #
  # @param [Integer, nil] index
  #
  # In context, this will yield a SQL JSON object.
  #
  # @return [String]
  #
  def job_arguments(index = nil)
    arguments = index ? "{arguments,#{index}}" : '{arguments}'
    %Q(serialized_params#>'#{arguments}')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
    extend THIS_MODULE
  end

end

__loading_end(__FILE__)
