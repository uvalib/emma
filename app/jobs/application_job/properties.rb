# app/jobs/application_job/properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ApplicationJob::Properties

  extend ActiveSupport::Concern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActiveJob::Core
    include ActiveJob::QueueName
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Job queue keys and priorities.
  #
  # @type [Hash{Symbol=>Integer}]
  #
  QUEUE_PRIORITY = {
    default:      00,
    background:   10,
    low_priority: 20,
    bulk:         30,
    normal:       40,
    max_pri:      50,
  }.freeze

  # All job queue keys.
  #
  # @type [Array<Symbol>]
  #
  QUEUE_KEYS = QUEUE_PRIORITY.keys.freeze

  # All job queue names.
  #
  # @type [Array<String>]
  #
  QUEUE_NAMES = QUEUE_KEYS.map(&:to_s).deep_freeze

  # The range of defined queue priorities.
  #
  # @type [Range]
  #
  PRIORITY_RANGE = QUEUE_PRIORITY.values.sort.then { |v| v.first..v.last }

  DEFAULT_KEY      = :normal
  DEFAULT_QUEUE    = DEFAULT_KEY.to_s.freeze
  DEFAULT_PRIORITY = QUEUE_PRIORITY[DEFAULT_KEY]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The queue key for the current job.
  #
  # @type [Symbol, nil]
  #
  def queue_key
    result = queue_name
    result = try(:arguments).presence && result.call if result.is_a?(Proc)
    result&.to_sym
  end

  # The defined priority for the current job.
  #
  # @type [Integer, nil]
  #
  def base_priority
    QUEUE_PRIORITY[queue_key]
  end

  # The queue key for the current job.
  #
  # @param [String, Symbol, Integer, Class, ApplicationJob, nil] val
  #
  # @type [Symbol, nil]
  #
  def queue_key_for(val)
    # noinspection RailsParamDefResolve
    case val
      when Integer then QUEUE_PRIORITY.invert[val]
      else              val.try(:queue_key) || val.try(:to_sym)
    end
  end

  # The defined priority for the current job.
  #
  # @param [String, Symbol, Integer, Class, ApplicationJob, nil] val
  #
  # @type [Integer, nil]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def priority_for(val)
    return val                                if val.nil? || val.is_a?(Integer)
    return QUEUE_PRIORITY[queue_key_for(val)] if val.respond_to?(:to_sym)
    result = val.try(:priority)
    result.is_a?(Integer) ? result : val.try(:base_priority)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ClassMethods

    include ApplicationJob::Properties

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveJob::QueueName::ClassMethods
      include ActiveJob::QueuePriority
      include ActiveJob::QueuePriority::ClassMethods
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @type [Symbol]
    mattr_accessor :default_queue_key, default: DEFAULT_KEY

    # =========================================================================
    # :section: ActiveJob::QueueName::ClassMethods overrides
    # =========================================================================

    public

    def queue_name_from_part(part_name)
      queue_name = part_name || default_queue_name
      name_parts = queue_name.to_s.split(queue_name_delimiter)
      prefix     = queue_name_prefix.presence
      prefix     = nil if name_parts.first == prefix
      -[prefix, *name_parts].compact.join(queue_name_delimiter)
    end

    # =========================================================================
    # :section: ActiveJob::QueuePriority::ClassMethods overrides
    # =========================================================================

    public

    def queue_with_priority(pri = nil, &blk)
      if blk
        block = -> { priority_for(instance_exec(&blk)) }
        super(&block)
        queue_as(&block) if queue_name.blank?
      else
        pri = priority_for(pri)
        super(pri)
        queue_as(priority) if queue_name.blank?
      end
    end

    # =========================================================================
    # :section: ApplicationJob::Properties overrides
    # =========================================================================

    public

    # The queue key for the current job.
    #
    # @type [Symbol]
    #
    def queue_key
      queue_name.is_a?(Proc) ? default_queue_key : queue_name.to_sym
    end

    # The defined priority for the current job.
    #
    # @type [Integer]
    #
    def base_priority
      # noinspection RubyMismatchedReturnType
      priority.is_a?(Integer) ? priority : QUEUE_PRIORITY[queue_key]
    end

  end

  module InstanceMethods

    extend ActiveSupport::Concern

    include ApplicationJob::Properties

    # =========================================================================
    # :section: ApplicationJob::Properties overrides
    # =========================================================================

    public

    # The queue key for the current job.
    #
    # @type [Symbol]
    #
    def queue_key
      super || default_queue_key
    end

    # The defined priority for the current job.
    #
    # @type [Integer]
    #
    def base_priority
      super || default_priority
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    included do
      delegate :default_queue_key,    to: :class
      delegate :default_queue_name,   to: :class
      delegate :default_priority,     to: :class
      delegate :queue_name_from_part, to: :class
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  included do

    include InstanceMethods

    self.default_queue_name = DEFAULT_QUEUE
    self.default_priority   = DEFAULT_PRIORITY

  end

end

__loading_end(__FILE__)
