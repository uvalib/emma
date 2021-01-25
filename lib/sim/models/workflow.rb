# lib/sim/models/workflow.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# These overrides are segregated from the normal code to make them easier to
# hide from Yard when generating documentation.

__loading_begin(__FILE__)

require_relative '../../../app/models/workflow'

# =============================================================================
# :section: Core
# =============================================================================

public

module Workflow::Base::Simulation

  include Emma::Debug
  include Workflow::Base::Data

  # ===========================================================================
  # :section: Classes
  # ===========================================================================

  public

  # A representation of an external task which simulates processing by
  # executing the check method until it returns false.
  #
  # Activation sequence is:
  #   start   # "Starts" the task by reinitializing its counter
  #   check   # Decrements the counter and returns *true* if still running.
  #
  class SimulatedTask

    attr_reader :label
    attr_reader :reps
    attr_reader :counter
    attr_reader :success
    attr_reader :running
    attr_reader :restartable

    def initialize(
      name: nil, result: true, reps: 3, started: nil, restart: nil
    )
      # noinspection RubyNilAnalysis
      a =
        case name
          when Array  then name.dup
          when String then name.strip.split(' ')
          else             self.class.name.demodulize.underscore.split('_')
        end
      a.unshift('async') unless a.first.match?(/async/i)
      a.push('task')     unless a.last.match?(/task/i)
      @label       = a.join(' ')
      @success     = result.present?
      @reps        = [0, reps].max
      @counter     = started ? @reps : 0
      @restartable = restart.present?
    end

    def running?
      @counter.positive?
    end

    def stopped?
      !running?
    end

    def stop
      @counter = 0
    end

    def start
      @counter = @reps
    end

    def restart
      start if restartable
    end

    def check
      running? && (@counter -= 1) && running?
    end

    def to_s
      @label
    end

    def self.inherited(subclass)
      subclass.class_eval do
        class << self

          def instance
            @instance ||= new
          end

          def to_s
            instance.to_s
          end

          delegate_missing_to :instance

        end
      end
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether simulation is in effect.
  #
  # @param [Boolean, nil] status
  #
  # @return [Boolean]
  #
  #--
  # noinspection RubyYardReturnMatch
  #++
  def simulating(status = nil)
    @simulating = status unless status.nil?
    @simulating = true   if @simulating.nil?
    @simulating
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Output for simulated action.
  #
  # @param [Array] args             Passed to #__debug_line.
  # @param [Proc]  block            Passed to #__debug_line.
  #
  # @return [nil]
  #
  def __debug_sim(*args, &block)
    # noinspection RubyNilAnalysis
    opt  = args.extract_options!.reverse_merge(leader: '   ')
    meth = args.first.is_a?(Symbol) ? args.shift : calling_method
    args.unshift(':%-20s' % meth)
    __debug_line(*args, **opt, &block)
  end

end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

# Hooks executed during transitions.
#
# == Usage Notes
# These are generally only of interest for detailed debugging because logic
# associated with specific transitions is applied by defining the appropriate
# "on_*_entry" method in WorkflowStates.
#
module Workflow::Base::Transitions

  include Workflow::Base::States

  # ===========================================================================
  # :section: Workflow overrides
  # ===========================================================================

  public

  # Generic state entry hook.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          _event       Triggering event
  # @param [Array]           _event_args
  #
  # @see Workflow::Specification#on_entry
  #
  def on_entry_hook(state, _event, *_event_args)
    __debug_hook('ENTER >>> [GENERIC]', state.to_sym)
  end

  # Generic state exit hook.
  #
  # @param [Workflow::State] state        State that is being exited.
  # @param [Symbol]          _event       Triggering event
  # @param [Array]           _event_args
  #
  # @see Workflow::Specification#on_exit
  #
  def on_exit_hook(state, _event, *_event_args)
    __debug_hook('<<< LEAVE [GENERIC]', state.to_sym)
  end

  # before_transition_hook
  #
  # @param [Symbol]    from         Starting state
  # @param [Symbol]    to           Ending state
  # @param [Symbol]    _event       Triggering event
  # @param [Array]     _event_args
  #
  # @see Workflow::Specification#before_transition
  #
  def before_transition_hook(from, to, _event, *_event_args)
    __debug_hook('>>>>>', from, to)
  end

  # on_transition_hook
  #
  # @param [Symbol]    from         Starting state
  # @param [Symbol]    to           Ending state
  # @param [Symbol]    _event       Triggering event
  # @param [Array]     _event_args
  #
  # @see Workflow::Specification#on_transition
  #
  def on_transition_hook(from, to, _event, *_event_args)
    __debug_hook('-----', from, to)
  end

  # after_transition_hook
  #
  # @param [Symbol]    from         Starting state
  # @param [Symbol]    to           Ending state
  # @param [Symbol]    _event       Triggering event
  # @param [Array]     _event_args
  #
  # @see Workflow::Specification#after_transition
  #
  def after_transition_hook(from, to, _event, *_event_args)
    __debug_hook('<<<<<', from, to)
  end

  # on_error_hook
  #
  # @param [Exception] error
  # @param [Symbol]    from         Starting state
  # @param [Symbol]    to           Ending state
  # @param [Symbol]    _event       Triggering event
  # @param [Array]     _event_args
  #
  # @see Workflow::Specification#on_error
  #
  def on_error_hook(error, from, to, _event, *_event_args)
    __debug_hook("!!!!! ERROR #{error} for ", from, to)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # __debug_hook
  #
  # @param [String]      label
  # @param [Symbol]      from       Starting state
  # @param [Symbol, nil] to         Ending state
  #
  def __debug_hook(label, from, to = nil)
    __debug_line do
      line = "WORKFLOW       TRANS #{label}".rstrip
      from = state_label(from)
      to   = to ? " -> #{state_label(to)}" : ''
      # noinspection RubyNilAnalysis
      chars  = line.size + from.size + to.size
      spaces = ' ' * [1, (80 - chars)].max
      "#{line}#{spaces}#{from}#{to}"
    end
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Redefine :workflow for a Workflow subclass in order to apply the methods
  # defined here to the matching workflow transition handlers.
  #
  # @param [Workflow, *] base
  #
  # @see Workflow::ClassMethods#workflow
  #
  def self.included(base)
    return unless base.respond_to?(:workflow)
    base.class_eval do
      def self.workflow(&specification)
        super(&specification)
        public_instance_methods.each do |method|
          next unless (handler = method.to_s.delete_suffix!('_hook'))
          workflow_spec.instance_eval <<~HEREDOC
            #{handler} do |*args|
              #{method}(*args)
            end
          HEREDOC
        end
      end
    end
  end

end if Workflow::Base::TRANSITION_DEBUG

__loading_end(__FILE__)
