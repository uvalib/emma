# app/jobs/application_job/logging.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions for job logging.
#
# == Usage Notes
# Include in each job class definition to resolve #job_name properly.
#
module ApplicationJob::Logging

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Debug

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def job_warn(*args, meth: nil, &block)
    return unless Log.warn?
    meth ||= calling_method
    Log.warn("#{self.class}::#{meth}", *args, &block)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def job_name
    @job_name ||= 'JOB %s' % (self.is_a?(Class) ? name : self.class.name)
  end

  def job_leader(job)
    @job_leader ||= "#{job.job_name} [#{job.job_id}]"
  end

  def job_inspect(job)
    "#{job_leader(job)} arguments: #{arguments_inspect(job)}"
  end

  def arguments_inspect(job)
    job.arguments.map { |v| item_inspect(v) }.join(' | ')
  end

  def record_inspect(r)
    "#{r.class.name}(id=#{r.id})"
  end

  def hash_inspect(h)
    h.to_h.map { |k, v| "#{k}: #{item_inspect(v)}" }.join(', ')
  end

  def array_inspect(a)
    '[%s]' % Array.wrap(a).map { |v| item_inspect(v) }.join(',')
  end

  def item_inspect(v)
    # noinspection RubyMismatchedArgumentType
    case v
      when ApplicationJob::AsyncCallback then "#{v.class} #{hash_inspect(v)}"
      when ApplicationRecord             then record_inspect(v)
      when Array                         then array_inspect(v)
      when Hash                          then hash_inspect(v)
      else                                    v.inspect
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def __debug_job(job, *args, **opt, &block)
    unless opt.key?(:leader) || !args.first.is_a?(ApplicationJob)
      # noinspection RubyMismatchedArgumentType
      opt[:leader] = "#{job_leader(args.first)}:"
    end
    __debug_line(*args, **opt, &block)
  end
    .tap { |meth| neutralize(meth) unless DEBUG_JOB }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ClassMethods
    include ApplicationJob::Logging
  end

  module InstanceMethods

    include ApplicationJob::Logging

    # =========================================================================
    # :section: ApplicationJob::Logging overrides
    # =========================================================================

    public

    def job_inspect(job = nil)
      # noinspection RubyMismatchedArgumentType
      super(job || self)
    end

    def arguments_inspect(job = nil)
      # noinspection RubyMismatchedArgumentType
      super(job || self)
    end

    # =========================================================================
    # :section: ApplicationJob::Logging overrides
    # =========================================================================

    public

    def __debug_job(*args, **opt, &block)
      args.prepend(self) unless args.first.is_a?(ApplicationJob)
      super(*args, **opt, &block)
    end
      .tap { |meth| neutralize(meth) unless DEBUG_JOB }

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  included do

    include InstanceMethods

    # =========================================================================
    # :section: ActiveJob callbacks
    # =========================================================================

    before_enqueue do |job|
      __debug_job(job) { "ENQUEUE START --->>> #{job_inspect(job)}" }
      # TODO: possible mechanism for making a job conditional; e.g.:
      # user = job.arguments.first
      # throw :abort unless user.wants_notification?
    end

    after_enqueue do |job|
      __debug_job(job) { "ENQUEUE END   <<<--- #{job_inspect(job)}" }
    end

    before_perform do |job|
      __debug_job(job) { "PERFORM START --->>> #{job_inspect(job)}" }
    end

    after_perform do |job|
      __debug_job(job) { "PERFORM END   <<<--- #{job_inspect(job)}" }
    end

  end

end

__loading_end(__FILE__)
