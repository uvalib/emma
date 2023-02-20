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

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActiveJob::Core
    include ActiveJob::Execution
    include ActiveJob::Logging
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # initialize
  #
  # @param [*]    args                Assigned to ActiveJob::Core#arguments.
  # @param [Hash] opt                 Appended to ActiveJob::Core#arguments.
  #
  def initialize(*args, **opt)
    __debug_job(__method__) { { args: args, opt: opt } }
    super()
    set_arguments(*args, **opt)
  end

  # ===========================================================================
  # :section: ActiveJob::Execution overrides
  # ===========================================================================

  public

  # Run the job asynchronously.
  #
  # @note The subclass *must* define its own #perform method; that definition
  #   *may* call this via `super` (but does not have to).
  #
  # @param [Array] args
  # @param [Hash]  opt
  #
  # @return [*]                       Return value of #perform.
  #
  def perform(*args, **opt)
    if is_a?(Class)
      job_warn { "not a class method | args = #{args.inspect}" }
    else
      set_arguments(*args, **opt)
    end
  end

  # Run the job immediately.
  #
  # @param [Array] args               Assigned to ActiveJob::Core#arguments.
  # @param [Hash]  opt
  #
  # @return [*]                       Return value of #perform.
  #
  def perform_now(*args, **opt)
    if is_a?(Class)
      # noinspection RubyArgCount
      super(*args, **opt)
    else
      set_arguments(*args, **opt) if args.present?
      super()
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # set_arguments
  #
  # @param [Array] args
  # @param [Hash]  opt
  #
  # @return [Array]                   New value of #arguments.
  #
  def set_arguments(*args, **opt)
    meth = opt.delete(:meth) || __method__
    unless respond_to?(:arguments)
      job_warn(meth: meth) { "not a class method | args = #{args.inspect}" }
      return []
    end
    if arguments.blank?
      args << opt if (opt = opt.presence && args.extract_options!.merge(opt))
      job_warn(meth: meth) { "arguments being set to #{args.inspect}" }
      return self.arguments = args
    end
    # noinspection RubyMismatchedArgumentType
    __debug_job(meth) { "`arguments` = #{arguments_inspect(self)}" }
    if (extra = args - arguments).present?
      job_warn(meth: meth) { "ignoring extra method args #{extra.inspect}" }
    elsif args.present?
      job_warn(meth: meth) { 'ignoring duplicate method args' }
    end
    arguments
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def job_warn(*args, meth: nil, &block)
    return unless Log.warn?
    meth ||= calling_method
    Log.warn("#{self_class}::#{meth}", *args, &block)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def job_name
    @job_name ||= "JOB #{self_class}"
  end

  def job_leader(job)
    job.is_a?(Class) ? "CLASS #{job}" : "#{job.job_name} [#{job.job_id}]"
  end

  def job_inspect(job)
    if job.is_a?(Class)
      job_leader(job)
    else
      "#{job_leader(job)} arguments: #{arguments_inspect(job)}"
    end
  end

  def arguments_inspect(job)
    job.arguments.map { |v| item_inspect(v) }.join(' | ')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

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

  def __debug_job(*args, **opt)
    unless opt.key?(:leader) || !args.first.is_a?(ActiveJob::Base)
      # noinspection RubyMismatchedArgumentType
      opt[:leader] = "#{job_leader(args.first)}:"
    end
    opt[:separator] ||= "\n\t"
    tid   = Thread.current.name
    name  = self_class
    args  = args.join(Emma::Debug::DEBUG_SEPARATOR)
    added = block_given? ? yield : {}
    __debug_items("#{name} #{args}", **opt) do
      added.is_a?(Hash) ? added.merge(thread: tid) : [*added, "thread #{tid}"]
    end
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
      unless args.first.is_a?(ActiveJob::Base) || !is_a?(ActiveJob::Base)
        args.prepend(self)
      end
      super(*args, **opt, &block)
    end
      .tap { |meth| neutralize(meth) unless DEBUG_JOB }

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  included do

    if respond_to?(:before_enqueue)

      # =======================================================================
      # :section: ActiveJob callbacks
      # =======================================================================

      before_enqueue do |job|
        __debug_job(job) { "--->>> ENQUEUE START #{job_inspect(job)}" }
        # TODO: possible mechanism for making a job conditional; e.g.:
        # user = job.arguments.first
        # throw :abort unless user.wants_notification?
      end

      after_enqueue do |job|
        __debug_job(job) { "<<<--- ENQUEUE END   #{job_inspect(job)}" }
      end

      before_perform do |job|
        __debug_job(job) { "--->>> PERFORM START #{job_inspect(job)}" }
      end

      after_perform do |job|
        __debug_job(job) { "<<<--- PERFORM END   #{job_inspect(job)}" }
      end

    end

  end

end

__loading_end(__FILE__)
