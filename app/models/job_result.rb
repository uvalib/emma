# app/models/job_result.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class JobResult < ApplicationRecord

  include JobMethods

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    extend JobMethods
  end
  # :nocov:

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  # noinspection RailsParamDefResolve
  belongs_to :active_job, class_name: 'GoodJob::Job', optional: true

  # ===========================================================================
  # :section: JobMethods overrides
  # ===========================================================================

  public

  # The associated subclass of GoodJob::Job.
  #
  # @return [Class]
  #
  def self.job_record_class
    base = name&.delete_suffix('JobResult')
    must_be_overridden if base.blank?
    "#{base}JobRecord".constantize
  end

  # Return the 'job_results' records involving the given client request.
  #
  # @param [String] stream
  #
  # @return [ActiveRecord::Relation<JobResult>]
  #
  def self.for(stream)
    job_key     = :active_job_id
    job_table   = job_record_class.table_name
    stream_name = job_record_class.stream_name
    sort_order  = implicit_order_column || :updated_at

    joins(<<~HEREDOC.squish).order(sort_order)
      INNER JOIN #{job_table}
        ON #{job_table}.#{job_key} = #{table_name}.#{job_key}
        WHERE #{job_table}.#{stream_name} = '#{stream}'
    HEREDOC
  end

end

__loading_end(__FILE__)
