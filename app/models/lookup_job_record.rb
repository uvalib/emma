# app/models/lookup_job_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Address only those 'good_jobs' records initiated by LookupJob.
#
class LookupJobRecord < GoodJob::Job

  include JobMethods

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :created_at

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  has_many :job_results

  default_scope { job_class(LookupJob) }

end

__loading_end(__FILE__)
