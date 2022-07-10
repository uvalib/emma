# app/models/lookup_job_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Address only those 'good_jobs' records initiated by LookupJob.
#
class LookupJobRecord < GoodJob::Job

  include JobMethods

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    extend JobMethods
    # :nocov:
  end

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :created_at

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  has_many :job_results

  default_scope { where(%q(serialized_params->>'job_class' = 'LookupJob')) }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  delegate :for, :service, :stream_name, to: :class

  # ===========================================================================
  # :section: JobMethods overrides
  # ===========================================================================

  public

  # The database column checked against the time of last reboot to determine
  # whether the record is defunct.
  #
  # @return [Symbol]
  #
  def self.activity_column
    :finished_at
  end

  delegate :activity_column, to: :class

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Select only the 'good_jobs' records involving this client request.
  #
  # @param [String] stream
  #
  # @return [ActiveRecord::Relation<LookupJobRecord>]
  #
  def self.for(stream)
    where(%Q(#{stream_name} = '#{stream}'))
  end

  # SQL fragment representing the lookup service in the data.
  #
  # In context, this will yield a SQL string value.
  #
  # @return [String]
  #
  def self.service
    %Q(#{job_service}->>'value')
  end

  # SQL fragment representing the stream name in the data.
  #
  # In context, this will yield a SQL string value.
  #
  # @return [String]
  #
  def self.stream_name
    %Q(#{job_options}->>'stream_name')
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # SQL fragment representing the items being looked up.
  #
  # In context, this will yield a SQL JSON object.
  #
  # @return [String]
  #
  def self.job_service
    job_arguments(0)
  end

  # SQL fragment representing the items being looked up.
  #
  # In context, this will yield a SQL JSON object.
  #
  # @return [String]
  #
  def self.job_items
    job_arguments(1)
  end

  # SQL fragment representing the ActiveJob options for the record.
  #
  # In context, this will yield a SQL JSON object.
  #
  # @return [String]
  #
  def self.job_options
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
  def self.job_arguments(index = nil)
    if index
      %q(serialized_params#>'{arguments,%d}') % index
    else
      %q(serialized_params#>'{arguments}')
    end
  end

end

__loading_end(__FILE__)
