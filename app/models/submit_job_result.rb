# app/models/submit_job_result.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class SubmitJobResult < JobResult

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.table_name = superclass.table_name
  self.implicit_order_column = :updated_at

  # ===========================================================================
  # :section: JobMethods overrides
  # ===========================================================================

  public

  # The associated subclass of GoodJob::Job.
  #
  # @return [Class]
  #
  def self.job_record_class
    SubmitJobRecord
  end

end

__loading_end(__FILE__)
