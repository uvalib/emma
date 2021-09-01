# app/models/concerns/record/controllable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common methods for ActiveRecord classes that support communication of control
# commands - either a :command and/or :condition column.
#
# @!attribute [rw] command
#   Database :command column.
#   @return [String]
#
# @!attribute [rw] condition
#   Database :condition column.
#   @return [String]
#
module Record::Controllable

  extend ActiveSupport::Concern

  include Record

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default name for the column which holds a command.
  #
  # @type [Symbol]
  #
  COMMAND_COLUMN = :command

  # The default name for the column which holds a condition.
  #
  # @type [Symbol]
  #
  CONDITION_COLUMN = :condition

  # Commands and the conditions they create.
  #
  # :run      Begin operation.
  #
  # :pause    For a multi-step sequence, allow the current step to complete and
  #           then wait until an indication is detected that the steps should
  #           resume.
  #
  # :wait     For a batch job, allow the current (possibly multi-step) sequence
  #           to complete and then wait until an indication is detected that
  #           the next sequence should begin.
  #
  # :resume   Return to the running state after a :pause or :wait.
  #
  # :retry    For a multi-step sequence, interrupt the current step, back out
  #           of any changes that might have been made from the previous steps,
  #           and then retry the sequence from the beginning.
  #
  # :restart  For a job that is finished unsuccessfully, rerun the job from the
  #           beginning.
  #
  # :abort    Interrupt the current job, back out of any changes that might
  #           have been made, and then terminate the job.
  #
  # :quit     Interrupt the current job, back out of any changes made for the
  #           current multi-step sequence, and then terminate the job.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # TODO: configuration instead of code ???
  #
  COMMAND_TABLE = {
    run:      { condition: :running                },
    pause:    { condition: :paused                 },
    wait:     { condition: :waiting                },
    resume:   { condition: :resuming               },
    retry:    { condition: :retrying               },
    restart:  { condition: :restarting             },
    abort:    { condition: :failed,    next: false },
    quit:     { condition: :succeeded, next: false },
  }.deep_freeze

  # Legal values for the :command column.
  #
  # @type [Array<Symbol>]
  #
  COMMANDS = COMMAND_TABLE.keys.freeze

  # Legal values for the :condition column.
  #
  # @type [Array<Symbol>]
  #
  CONDITIONS = COMMAND_TABLE.map { |_, v| v[:condition] }.compact.uniq.freeze

  # Conditions which indicate that the associated action is done.
  #
  # @type [Array<Symbol>]
  #
  FINAL_CONDITIONS =
    COMMAND_TABLE.map { |_, v|
      v[:condition] if v[:next].is_a?(FalseClass)
    }.compact.uniq.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # SQL fragment for selecting a :condition which is final.
  #
  # @return [String]
  #
  def final_condition
    'condition IN (%s)' % quote(FINAL_CONDITIONS)
  end

  # Does the condition indicate that the associated action is done?
  #
  # @param [Symbol, String] current
  #
  def finished?(current, **)
    FINAL_CONDITIONS.include?(current&.to_sym)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Definitions to be included if the schema contains a :command column.
  #
  # @!method run?
  # @!method pause?
  # @!method wait?
  # @!method resume?
  # @!method retry?
  # @!method restart?
  # @!method abort?
  # @!method quit?
  #
  # @!method run!
  # @!method pause!
  # @!method wait!
  # @!method resume!
  # @!method retry!
  # @!method restart!
  # @!method abort!
  # @!method quit!
  #
  module CommandMethods

    extend ActiveSupport::Concern

    include Record
    include Record::Controllable

    # =========================================================================
    # :section:
    # =========================================================================

    private

    THIS_MODULE = self

    included do |base|

      __included(base, THIS_MODULE)
      assert_record_class(base, THIS_MODULE)

      include Record::Updatable

      # =======================================================================
      # :section:
      # =======================================================================

      public

      enum_methods COMMAND_COLUMN => COMMANDS

    end

  end

  # Definitions to be included if the schema contains a :condition column.
  #
  # @!method running?
  # @!method paused?
  # @!method waiting?
  # @!method resuming?
  # @!method retrying?
  # @!method restarting?
  # @!method failed?
  # @!method succeeded?
  #
  # @!method running!
  # @!method paused!
  # @!method waiting!
  # @!method resuming!
  # @!method retrying!
  # @!method restarting!
  # @!method failed!
  # @!method succeeded!
  #
  module ConditionMethods

    extend ActiveSupport::Concern

    include Record
    include Record::Controllable

    # =========================================================================
    # :section: Record::Controllable overrides
    # =========================================================================

    public

    # Does the current condition indicate that the associated action is done?
    #
    # @param [Symbol, String, nil] current  Default: `self[CONDITION_COLUMN]`
    #
    def finished?(current = nil, **)
      super(current || self[CONDITION_COLUMN])
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    THIS_MODULE = self

    included do |base|

      __included(base, THIS_MODULE)
      assert_record_class(base, THIS_MODULE)

      include Record::Updatable

      # =======================================================================
      # :section:
      # =======================================================================

      public

      enum_methods CONDITION_COLUMN => CONDITIONS

    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include CommandMethods   if has_column?(COMMAND_COLUMN)
    include ConditionMethods if has_column?(CONDITION_COLUMN)

  end

end

__loading_end(__FILE__)
