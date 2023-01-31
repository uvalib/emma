# app/models/lookup_job_result.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class LookupJobResult < JobResult

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.table_name = superclass.table_name
  self.implicit_order_column = :updated_at

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Return the 'job_results' records involving the given client request.
  #
  # @param [String] stream
  #
  # @return [ActiveRecord::Relation<JobResult>]
  #
  def self.for(stream)
    job_key     = :active_job_id
    job_class   = LookupJobRecord
    job_table   = job_class.table_name
    stream_name = job_class.stream_name

    joins(<<~HEREDOC.squish).order(:updated_at)
      INNER JOIN #{job_table}
        ON #{job_table}.#{job_key} = #{table_name}.#{job_key}
        WHERE #{job_table}.#{stream_name} = '#{stream}'
    HEREDOC
  end

end

__loading_end(__FILE__)
