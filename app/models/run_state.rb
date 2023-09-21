# app/models/run_state.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class RunState < Hash

  include Emma::Common
  include Emma::Json

  # @private
  CLASS = self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If *true*, then PUT "/health/run_state" will clear the RunState initially
  # set at system startup. This allows a system which starts unavailable to be
  # made available at some point.
  #
  # @type [Boolean]
  #
  CLEARABLE = true

  # If *true*, then allow RunState to be changed dynamically, allowing for the
  # system to be repeatedly made available/unavailable.
  #
  # NOTE: Not recommended for production at this time.
  #
  # @type [Boolean]
  #
  DYNAMIC = false

  # If *true*, then RunState is set at system startup and cannot be changed.
  #
  # @type [Boolean]
  #
  STATIC = !CLEARABLE && !DYNAMIC

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The run states and their properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # === Implementation Notes
  # If further states are added, they should be added between :available and
  # :unavailable so that they maintain their first/last positions.
  #
  STATE =
    I18n.t('emma.health.run_state.state', default: {}).map { |state, entry|
      values = { state: state.to_s }.merge!(entry[:property] || {})
      [state, values]
    }.compact.to_h.deep_freeze

  # * AVAILABLE_STATUS references the run state for normal operation.
  # * UNAVAILABLE_STATUS is the run state for general system unavailability.
  AVAILABLE_STATUS, *, UNAVAILABLE_STATUS = STATE.keys

  # Defaults for the "available" run state.
  #
  # @type [Hash{Symbol=>String,Integer}]
  #
  AVAILABLE_DEFAULTS = STATE[AVAILABLE_STATUS]

  # Defaults for the "unavailable" run state.
  #
  # @type [Hash{Symbol=>String,Integer}]
  #
  UNAVAILABLE_DEFAULTS = STATE[UNAVAILABLE_STATUS]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The run state status expressed as one of `#STATE.keys`.
  # (Derived from `self[:state]`).
  #
  # @return [Symbol]
  #
  attr_reader :status

  # The HTTP result code associated with the run state.
  # (Derived from `self[:code]`).
  #
  # @return [Integer]
  #
  attr_reader :code

  # The text-only message associated with the run state.
  # (Derived from `self[:text]`, `self[:message]`, or `self[:html]`).
  #
  # @return [String]
  #
  attr_reader :text

  # The HTML-ready message associated with the run state.
  # (Derived from `self[:html]` or `self[:message]`).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  attr_reader :html

  # The "Retry-After" time expressed as either a timestamp or seconds.
  # (Derived from `self[:retry_after]`).
  #
  # @return [Time, Integer, nil]
  #
  # @see #timestamp_or_duration
  #
  attr_reader :after

  # List of attribute accessors for instances of this class.
  #
  # @type [Array<Symbol>]
  #
  ATTR_METHODS = instance_methods(false).dup.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new run state instance.
  #
  # With no arguments, a RunState is created which indicates that the system
  # is available.
  #
  # If the argument is *true* or "true", a RunState is created which indicates
  # that the system is unavailable.
  #
  # @param [String, Boolean, Hash, RunState, Any, nil] source
  #
  def initialize(source = nil)
    if source.blank?
      source  = AVAILABLE_DEFAULTS
    elsif true?(source)
      source  = UNAVAILABLE_DEFAULTS
    else
      default = AVAILABLE_DEFAULTS.merge(text: "invalid: #{source.inspect}")
      source  = safe_json_parse(source, log: false, default: default)
    end
    # noinspection RubyMismatchedArgumentType
    merge!(source)
    @status ||= UNAVAILABLE_STATUS
    @code   ||= STATE.dig(@status, :code)
    @text   ||= STATE.dig(@status, :text)
    @html   ||= ERB::Util.h(@text)
  end

  # ===========================================================================
  # :section: Hash overrides
  # ===========================================================================

  public

  # Override Hash#merge! to set/update attributes.
  #
  # @param [Array<RunState,Hash>] others
  #
  # @return [self]
  #
  def merge!(*others)
    super.tap do
      if (rs = others.reverse.find { |other| other.is_a?(RunState) })
        attr_values = ATTR_METHODS.map { |attr| [attr, rs.send(attr)] }.to_h
      else
        others.map! { |other|
          v = {}
          v[:status] = other[:state]&.to_sym
          v[:code]   = other[:code]&.to_i
          v[:html]   = other[:html] || other[:message]
          v[:text]   = other[:text] || other[:message] || other[:html]
          v[:text]   = sanitized_string(v[:text]).presence
          v[:after]  = other[:after] || other[:retry_after]
          v[:after]  = timestamp_or_duration(v[:after])
          v.compact.presence
        }.compact!
        attr_values = {}.merge!(*others)
      end
      attr_values.compact.each do |attr, value|
        value = normalize_value(value)
        next if value.nil?
        case attr
          when :status then value = ":#{value}"
          when :html   then value = value.inspect << '.html_safe'
          else              value = value.inspect
        end
        # noinspection RubyResolve, RubyInstanceVariableNamingConvention
        eval("@#{attr} = #{value}")
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Prepare a source value for assignment during initialization.
  #
  def normalize_value(v)
    v = v.to_s  if v.is_a?(Symbol)
    v = v.strip if v.is_a?(String)
    v.is_a?(FalseClass) ? v : v.presence
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the system should be available.
  #
  def available?
    status == :available
  end

  # Indicate whether the system should be unavailable.
  #
  def unavailable?
    !available?
  end

  # The value for the 'Retry-After' header: either a string representing a
  # duration in seconds, or a time
  #
  # @return [String, nil]
  #
  def retry_value
    v = @after.presence
    v.is_a?(Time) ? v.gmtime.strftime('%a, %d %b %Y %H:%M:%S GMT') : v&.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A regular expression  pattern fragment allowing for a duration to be
  # expressed as, for example, "+ 30.minutes" or "in 30.minutes".
  #
  # @type [String]
  #
  PLUS = %w[\+ in].join('|').freeze

  # A table of abbreviations with their matching time units.
  #
  # @type [Hash{String=>String}]
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  ABBREV_UNIT = {
    sec: 'second',
    min: 'minute',
    hr:  'hour',
    dy:  'day',
    wk:  'week'
  }.stringify_keys!.freeze

  # A regular expression pattern fragment for time units.
  #
  # @type [String]
  #
  UNITS = ABBREV_UNIT.values.map { |u| "#{u}s?" }.join('|')

  # A regular expression pattern fragment for time unit abbreviations.
  #
  # @type [String]
  #
  ABBREVS = ABBREV_UNIT.keys.map { |u| "#{u}s?" }.join('|')

  # Transform a value into either a duration (as an integral number of seconds)
  # or a fixed timestamp.
  #
  # @param [String, Integer, ActiveSupport::Duration, Time, Any] v
  #
  # @return [Time, Integer, nil]
  #
  # @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def timestamp_or_duration(v)
    unless (v = v.presence).nil? || digits_only?(v)
      v = v.sub(/^\s*(#{PLUS})\s*/i, 'Time.now + ')
      v.gsub!(/(\d+)\s+(#{UNITS})(?=[^[:alpha:]]|$)/i) do
        unit = $2.to_s.downcase
        "#{$1}.#{unit}"
      end
      v.gsub!(/(\d+)(\.|\s+)(#{ABBREVS})(?=[^[:alpha:]]|$)/i) do
        abbr = $3.to_s.downcase.delete_suffix('s')
        unit = ABBREV_UNIT[abbr]
        "#{$1}.#{unit}"
      end
      # noinspection RubyMismatchedArgumentType
      v = eval(v) rescue nil
    end
    return v if v.nil? || v.is_a?(Time)
    v if (v = v.to_i).positive?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  class << self

    # The current run state.
    #
    # @return [RunState]
    #
    def current
      @current ||= RunState.new
    end

    # Set the current run state.
    #
    # @param [Hash, String, Any, nil] source
    #
    # @return [void]
    #
    def set_current(source)
      @current = new(source)
      debug { "#{@current[:state].upcase} | source = #{source.inspect}" }
    end

    # Clear the current run state.
    #
    # @return [void]
    #
    def clear_current
      @current = nil
      debug { 'RUN STATE CLEARED' }
    end

    if DYNAMIC

      # The relative path to the file which is used to communicate the current
      # run state between threads.
      #
      # @type [String]
      #
      # === Implementation Notes
      # This is in "tmp/pids" for extra assurance because that directory is
      # cleared on startup by the infrastructure.
      #
      #--
      # noinspection RbsMissingTypeSignature
      #++
      STATE_FILE = 'tmp/pids/run_state'

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # The current run state, initialized to the contents of #STATE_FILE.
      #
      # @return [RunState]
      #
      def current
        @current ||= new(state_file_read)
      end

      # Set the current run state by replacing the contents of #STATE_FILE.
      #
      # @param [Hash, String, Any] source
      #
      # @return [void]
      #
      def set_current(source)
        state = source.presence
        state &&= new(source)
        if state&.unavailable?
          debug { "UNAVAILABLE | source = #{source.inspect}" }
          state_file_write(state)
        else
          debug { "AVAILABLE | source = #{source.inspect}" }
          state_file_clear
        end
        @current = nil
      end

      # Clear the current run state and remove #STATE_FILE.
      #
      # @return [void]
      #
      def clear_current
        debug { 'RUN STATE CLEARED' }
        state_file_clear
        @current = nil
      end

      # =======================================================================
      # :section:
      # =======================================================================

      private

      # Indicate whether the state file is present.
      #
      def state_file_exist?
        File.exist?(STATE_FILE)
      end

      # Ensure that the state file is removed.
      #
      def state_file_clear
        File.delete(STATE_FILE) if state_file_exist?
      end

      # Get the contents of the state file.
      #
      # @return [String]
      # @return [nil]                 If #STATE_FILE does not exist.
      #
      def state_file_read
        return unless state_file_exist?
        begin
          File.open(STATE_FILE, File::RDONLY) do |f|
            f.flock(File::LOCK_SH)
            f.read
          end
        rescue => error
          warn(error)
          re_raise_if_internal_exception(error)
        end
      end

      # Create or update the contents of the state file.
      #
      # @param [String, Hash] state
      #
      # @return [String]
      # @return [nil]                 If #STATE_FILE could not be created.
      #
      def state_file_write(state)
        state = state.to_json unless state.is_a?(String)
        File.open(STATE_FILE, (File::RDWR | File::CREAT)) do |f|
          f.flock(File::LOCK_EX)
          f.write(state)
        end
        # noinspection RubyMismatchedReturnType
        state
      rescue => error
        warn(error)
        re_raise_if_internal_exception(error)
      end

    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # Add a warning-level log message.
    #
    # @param [Array<*>]             args    Passed to #log.
    # @param [Symbol, nil]          meth    Calling method.
    # @param [Proc]                 block   Passed to #log.
    #
    # @return [nil]
    #
    def warn(*args, meth: nil, **, &block)
      log(*args, level: Log::WARN, meth: meth, &block) if Log.warn?
    end

    # Add a debug-level log message.
    #
    # @param [Array<*>]             args    Passed to #log.
    # @param [Symbol, nil]          meth    Calling method.
    # @param [Proc]                 block   Passed to #log.
    #
    # @return [nil]
    #
    def debug(*args, meth: nil, **, &block)
      log(*args, level: Log::DEBUG, meth: meth, &block) if Log.debug?
    end

    # Add a log message.
    #
    # @param [Array<*>]             args    Passed to Emma::Log#add
    # @param [Integer, Symbol, nil] level   Severity level.
    # @param [Symbol, nil]          meth    Calling method.
    # @param [Proc]                 block   Passed to Emma::Log#add
    #
    # @return [nil]
    #
    def log(*args, level:, meth: nil, **, &block)
      meth ||= calling_method(3)
      Log.add(level, "#{CLASS}::#{meth}", *args, &block)
    end

    delegate_missing_to :current

  end

  # ===========================================================================
  # :section: Establish configured system availability as soon as possible
  # ===========================================================================

  set_current(ENV['SERVICE_UNAVAILABLE'])

end

__loading_end(__FILE__)
