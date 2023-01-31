# app/models/submit_job_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Address only those 'good_jobs' records initiated by SubmitJob.
#
class SubmitJobRecord < GoodJob::Job

  include JobMethods

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :created_at

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  has_many :job_results

  default_scope { job_class(SubmitJob) }

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # active_for
  #
  # @param [SubmitJob, Manifest, String, *] manifest
  #
  # @return [ActiveRecord::Relation<SubmitJobRecord>, nil]
  #
  def self.active_for(manifest)
    queue = SubmitJob.queue_for(manifest)
    where(queue_name: queue).and(running) unless queue.blank?
  end

end

__loading_end(__FILE__)
