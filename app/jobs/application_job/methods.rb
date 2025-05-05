# app/jobs/application_job/methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ApplicationJob::Methods

  extend ActiveSupport::Concern

  include Emma::TimeMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # JobResult table columns with information.
  #
  # @type [Array<Symbol>]
  #
  JOB_RESULT_COLUMNS = %i[output error diagnostic].freeze

  # JobResult table column with result data.
  #
  # @type [Symbol]
  #
  MAIN_JOB_RESULT_COLUMN = JOB_RESULT_COLUMNS.first

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Extract job results from the 'job_results' database table.
  #
  # @param [String]                  job_id   The :active_job_id column value
  #                                             for the record to get.
  # @param [Array,Symbol,String,nil] path     If provided, the path into the
  #                                             JSON hierarchy.
  # @param [Symbol]                  column   The data column to get.
  #
  # @return [Hash]
  # @return [nil]                     If the requested data was not found.
  #
  def job_result(job_id:, path: nil, column: MAIN_JOB_RESULT_COLUMN, **)
    raise "#{column}: invalid" unless JOB_RESULT_COLUMNS.include?(column)

    result = JobResult.where(active_job_id: job_id).pluck(column).first
    return unless result.is_a?(Hash)

    type   = result[:class]&.to_s&.safe_constantize
    result = type.template.merge(result) if type&.respond_to?(:template)
    return result if path.blank?

    path = path.is_a?(Array) ? path.map(&:to_s) : path.to_s.split('/')
    result.dig(*path.compact_blank)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The time elapsed past the given deadline.
  #
  # @param [Float, Integer, nil] deadline
  # @param [Float, Integer, nil] current   Default `#timestamp`.
  # @param [Float]               epsilon
  #
  # @return [Float, nil]
  #
  def past_due(deadline, current = nil, epsilon: EPSILON)
    return unless deadline
    current  = current&.to_f || timestamp
    overtime = current - deadline.to_f
    positive_float(overtime, epsilon: epsilon)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The instrumentation notification which causes the waiter task to update its
  # tally of results and send a response back to the client if all tasks have
  # either completed or timed-out.
  #
  # @type [String]
  #
  TASK_END_NOTIFICATION = 'finished_job_task.good_job'

  # @return [ActiveSupport::Notifications::Fanout::Subscribers::Evented]
  attr_accessor :subscriber

  # Listen for task completion.
  #
  # @return [ActiveSupport::Notifications::Fanout::Subscribers::Evented]
  #
  # @yield Event details
  # @yieldparam [String] event_name
  # @yieldparam [Time]   event_start
  # @yieldparam [Time]   event_finish
  # @yieldparam [String] event_id
  # @yieldparam [Hash]   event_payload
  #
  def notifications_subscribe(&blk)
    self.subscriber =
      ActiveSupport::Notifications.subscribe(TASK_END_NOTIFICATION, &blk)
  end

  # Undo previous #notifications_subscribe.
  #
  # @param [ActiveSupport::Notifications::Fanout::Subscribers::Evented, nil] subscriber
  #
  def notifications_unsubscribe(subscriber = nil)
    subscriber ||= self.subscriber
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
    base.extend(THIS_MODULE)
  end

end

__loading_end(__FILE__)
