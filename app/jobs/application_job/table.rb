# app/jobs/application_job/table.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Job table for waiter tasks.
#
class ApplicationJob::Table < Concurrent::Hash

  include ApplicationJob::Methods
  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Array<ActiveJob::Base,String>] job_list   Jobs or job IDs.
  #
  def initialize(job_list)
    job_table =
      job_list.map { |job|
        job = job.job_id if job.is_a?(ActiveJob::Base)
        [job, nil]
      }.to_h
    replace(job_table)
  end

  # ===========================================================================
  # :section: Hash overrides
  # ===========================================================================

  public

  # Update job entry.
  #
  # @param [String]    job_id
  # @param [Hash, nil] data
  #
  # @return [*]
  #
  def []=(job_id, data)
    super(job_id, data&.except(:active_job_id))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the job (or all jobs) have been completed.
  #
  # @param [String, nil] job_id
  #
  def completed?(job_id = nil)
    if job_id
      include?(job_id) && !self[job_id].nil?
    else
      present? && values.none?(&:nil?)
    end
  end

  # Indicate whether the job (or all jobs) have not been completed.
  #
  # @param [String, nil] job_id
  #
  def pending?(job_id = nil)
    if job_id
      include?(job_id) && self[job_id].nil?
    else
      present? && values.all?(&:nil?)
    end
  end

  # Indicate whether all jobs have been completed.
  #
  def all_completed? = completed?

  # Indicate whether all jobs have not been completed.
  #
  def all_pending? = pending?

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get all given job result values.
  #
  # @param [Symbol] result_key
  #
  # @return [Array<Hash>]
  #
  def result_values(result_key)
    values.map { |job_result| job_result[result_key] }.compact
  end

  # Extract overall table information.
  #
  # @return [Hash]
  #
  def summarize
    total = 0
    error = []
    each_pair do |job_id, job_result|
      unless (count = non_negative(job_result[:count]))
        data  = job_result[:data]
        items = data.is_a?(Hash) && data[:items] || data
        count = job_result[:count] = Array.wrap(items).size
      end
      total += count
      error << job_id if job_result[:late] || job_result[:error]
    end
    { total: total, error: error.presence }.compact
  end

end

__loading_end(__FILE__)
