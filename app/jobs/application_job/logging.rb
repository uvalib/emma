# app/jobs/application_job/logging.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions for job logging.
#
module ApplicationJob::Logging

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Debug
  include Emma::ThreadMethods

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActiveJob::Execution
    include ActiveJob::Logging
    # :nocov:
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
    args << args.extract_options!.merge(opt) if opt.present?
    if !respond_to?(:arguments)
      job_warn(meth: meth) { "not a class method | args = #{args.inspect}" }
      return []
    elsif arguments.blank?
      self.arguments = args
    elsif args.blank?
      job_warn(meth: meth) { 'ignoring empty method args' }
    elsif (extra = args - arguments).present?
      job_warn(meth: meth) { "ignoring extra method args #{extra.inspect}" }
    else
      __debug_job(meth, 'ignoring duplicate method args')
    end
    __debug_job(meth, "(#{arguments.size} args)") { arguments_inspect }
    arguments
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def job_warn(*args, meth: nil, &blk)
    return unless Log.warn?
    meth ||= calling_method
    Log.warn("#{self_class}::#{meth}", *args, &blk)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TAG_LEADER = 'JOB'

  def job_tag(arg = nil, tag: nil, tid: nil, **)
    arg ||= self
    name  = arg.is_a?(Class) ? arg     : arg.class
    tag ||= arg.is_a?(Class) ? 'CLASS' : arg.job_id
    tid ||= thread_name
    "#{TAG_LEADER} #{name} [#{tid}] [#{tag}]"
  end

  def job_inspect(job = nil)
    job ||= self
    if job.is_a?(Class)
      job_tag(job)
    else
      # noinspection RubyMismatchedArgumentType
      "#{job_tag(job)} arguments: #{arguments_inspect(job)}"
    end
  end

  def arguments_inspect(job = nil)
    # noinspection RailsParamDefResolve
    (job || self).try(:arguments)&.map { |v| item_inspect(v) }&.join(' | ')
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
    case v
      when ApplicationRecord then record_inspect(v)
      when Array             then array_inspect(v)
      when Hash              then hash_inspect(v)
      else                        v.inspect
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Send debugging output to the console.
  #
  # @param [Array<*>] args
  # @param [Hash]     opt
  # @param [Proc]     blk             Passed to #__debug_items
  #
  # @return [nil]
  #
  def __debug_job(*args, **opt, &blk)
    args.compact!
    case args.first
      when ActiveJob::Base, Class then job = args.shift
      when /^#{TAG_LEADER} /      then job = args.shift
      else                             job = self
    end
    # noinspection RubyMismatchedArgumentType
    opt[:leader]    = "#{job_tag(job)}:" unless opt.key?(:leader)
    opt[:compact]   = true               unless opt.key?(:compact)
    opt[:separator] = "\n\t"             unless opt.key?(:separator)
    __debug_items(args.join(DEBUG_SEPARATOR), **opt, &blk)
  end
    .tap { |meth| neutralize(meth) unless DEBUG_JOB }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ClassMethods
    include ApplicationJob::Logging
  end

end

__loading_end(__FILE__)
