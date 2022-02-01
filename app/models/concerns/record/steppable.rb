# app/models/concerns/record/steppable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'updatable'

# Common methods for ActiveRecord classes that are used to track outcomes
# across multiple steps.
#
# @!attribute [rw] state
#   Database :state column.
#   @return [String]
#
# == Usage Notes
# If the including class does not define a STATE_TABLE constant before the
# include of this module, #generate_state_methods will need to be run
# explicitly with a Hash with state values as keys.
#
module Record::Steppable

  extend ActiveSupport::Concern

  include Record

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default state column name.                                              # NOTE: from Upload::WorkflowMethods::STATE_COLUMNS
  #
  # @type [Symbol]
  #
  STATE_COLUMN = :state

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Workflow state configurations.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/state_table.en.yml *en.emma.state_table*
  #
  #--
  # noinspection RailsI18nInspection
  #++
  STATE_TABLES =
    I18n.t('emma.state_table', default: {}).transform_values { |leaf_classes|
      leaf_classes.transform_values do |states|
        states.transform_values { |entry|
          next unless entry.is_a?(Hash)
          entry.map { |item, value|
            case item
              when :meth
                value = value.strip.delete_prefix(':') if value.is_a?(String)
                value = (value.to_sym unless value.blank? || false?(value))
              when :next
                value =
                  Array.wrap(value).map { |v|
                    v = v.strip.delete_prefix(':').to_sym if v.is_a?(String)
                    v unless v.blank? || false?(v)
                  }.compact
                value = false if value.empty?
              when :note_proc
                item = :note
                value = value.strip
                value = "->(*, **) { #{value} }" unless value.start_with?('->')
                value = eval(value) rescue 'BAD PROC'
              else
                value = value.strip if value.is_a?(String)
            end
            [item, value] unless value.nil?
          }.compact.to_h
        }.compact
      end
    }.deep_freeze

  # Groupings of states related by theme.                                       # NOTE: from Upload::WorkflowMethods
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/controllers/entry.en.yml *en.emma.entry.state_group*
  #
  #--
  # noinspection RailsI18nInspection
  #++
  STATE_GROUP =
    I18n.t('emma.entry.state_group', default: {}).transform_values { |entry|
      states = Array.wrap(entry[:states]).map(&:to_sym)
      entry.merge(states: states)
    }.deep_freeze

  # Mapping of workflow state to category.                                      # NOTE: from Upload::WorkflowMethods
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  REVERSE_STATE_GROUP =
    STATE_GROUP.flat_map { |group, entry|
      entry[:states].map { |state| [state,  group] }
    }.sort.to_h.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The database column currently associated with the workflow state of the
  # record.
  #
  # @return [Symbol]
  #
  def state_column(*)                                                           # NOTE: from Upload::WorkflowMethods
    STATE_COLUMN
  end

  # Workflow state table associated with *item*.
  #
  # @param [Model, Class<Model>] item
  #
  # @return [Hash]
  #
  def state_table(item)
    get_state_table(item) || {}
  end

  # Workflow state configuration for *item*.
  #
  # @param [Model, Class<Model>] item
  # @param [Boolean]             no_raise
  #
  # @return [Hash, nil]
  #
  def get_state_table(item, no_raise: true)
    return unless item
    cls = item.is_a?(Class) ? item : item.class
    if cls.respond_to?(:type_value)
      result = cls.safe_const_get(:STATE_TABLE, false) and return result
      base   = cls.module_parent.type_value
      type   = cls.type_value
      result = STATE_TABLES.dig(base, type)            and return result
      error  = "STATE_TABLES[#{base}][#{type}] invalid"
    else
      error = "invalid: #{item.inspect}"
    end
    Log.warn { "#{__method__}: #{error}" }
    raise error unless no_raise
  end

  # All valid workflow states for *item*.
  #
  # @param [Model, Class<Model>] item
  #
  # @return [Array<Symbol>]
  #
  def get_state_names(item)
    state_table(item).keys
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Cast value in a form for comparison.
  #
  # @param [Model, Symbol, String, nil] item
  #
  # @return [Symbol, nil]
  #
  def state_value(item)
    return if item.blank?
    # noinspection RubyNilAnalysis
    if item.is_a?(Symbol) || item.is_a?(String)
      item.to_sym
    elsif item.respond_to?(:state_value)
      item.state_value
    elsif item.is_a?(Model)
      raise "#{item.class} does not support #{__method__}"
    else
      raise "#{__method__}: #{item.class}: invalid"
    end
  end

  # Get the configured descriptive note for the state.
  #
  # @param [Model, Symbol, String, nil] item
  #
  # @return [String, nil]
  #
  def state_note(item)
    s = state_value(item) or return
    state_table.dig(s, :note)
  end

  # Get a natural-language description for the state.
  #
  # @param [Model, Symbol, String, nil] item
  #
  # @return [String, nil]
  #
  def state_description(item)
    s = state_value(item) or return
    state_table.dig(s, :note) || s.to_s.humanize(capitalize: false)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether this record represents an existing EMMA entry.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def existing_entry?(item)                                                     # NOTE: from Upload::WorkflowMethods
    state_value(item) == :completed
  end

  # Indicate whether this record represents an existing EMMA entry.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def new_submission?(item)                                                     # NOTE: from Upload::WorkflowMethods
    !existing_entry?(item)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the group of the given state.
  #
  # @param [Model, String, Symbol, nil] item
  #
  # @return [Symbol]  Defaults to :all if *target_state* is invalid.
  #
  def state_group(item)                                                         # NOTE: from Upload::WorkflowMethods
    # noinspection RubyNilAnalysis
    if item.is_a?(String) || item.is_a?(Symbol)
      state = item.to_sym
    else
      state = state_value(item)
    end
    REVERSE_STATE_GROUP[state] || :all
  end

  # Return the label for the given state group.
  #
  # @param [Model, String, Symbol, nil] group
  #
  # @return [String]
  # @return [nil]                     If *group* is invalid.
  #
  def state_group_label(group)                                                  # NOTE: from Upload::WorkflowMethods
    if group.is_a?(String) || group.is_a?(Symbol)
      # noinspection RubyNilAnalysis
      group = group.to_sym
    else
      group = state_group(group)
      group = nil if group == :all
    end
    STATE_GROUP.dig(group, :label)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether this record is involved in a workflow step related to
  # the creation of a new EMMA entry.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def being_created?(item)                                                      # NOTE: from Upload::WorkflowMethods
    state_group(item) == :create
  end

  # Indicate whether this record is involved in a workflow step related to
  # the modification of an existing EMMA entry.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def being_modified?(item)                                                     # NOTE: from Upload::WorkflowMethods
    state_group(item) == :edit
  end

  # Indicate whether this record is involved in a workflow step related to
  # the removal of an existing EMMA entry.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def being_removed?(item)                                                      # NOTE: from Upload::WorkflowMethods
    state_group(item) == :remove
  end

  # Indicate whether this record is involved in a workflow step related to
  # the review process.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def under_review?(item)                                                       # NOTE: from Upload::WorkflowMethods
    state_group(item) == :review
  end

  # Indicate whether this record is involved in a workflow step related to
  # transmission to a member repository.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def being_submitted?(item)                                                    # NOTE: from Upload::WorkflowMethods
    state_group(item) == :submission
  end

  # Indicate whether this record is involved in a workflow step related to
  # ingest into the EMMA Unified Index.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def being_indexed?(item)                                                      # NOTE: from Upload::WorkflowMethods
    state_group(item) == :finalization
  end

  # Indicate whether this record is involved in a workflow step related to
  # ingest into the EMMA Unified Index.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def completed?(item)                                                          # NOTE: from Upload::WorkflowMethods
    state_group(item) == :done
  end

  # Indicate whether this record is involved in a workflow step which leads
  # to a change in the associated EMMA index entry.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def in_process?(item)                                                         # NOTE: from Upload::WorkflowMethods
    item = state_group(item)
    being_submitted?(item) || being_indexed?(item)
  end

  # Indicate whether this record is involved in a workflow step where
  # non-administrative data (EMMA or file data) could be changed.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def unsealed?(item)                                                           # NOTE: from Upload::WorkflowMethods
    item = state_group(item)
    being_created?(item) || being_modified?(item) || being_removed?(item)
  end

  # Indicate whether this record is *not* involved in a workflow step where
  # non-administrative data (EMMA or file data) could be changed.
  #
  # @param [Model, String, Symbol, nil] item
  #
  def sealed?(item)                                                             # NOTE: from Upload::WorkflowMethods
    !unsealed?(item)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # job_class
  #
  # @param [Model, Class<Model>] item
  #
  # @return [Class<ApplicationJob>]
  #
  def job_class(item)
    cls = item.is_a?(Class) ? item : item.class
    # noinspection RubyMismatchedReturnType
    "#{cls.name}::WorkflowJob".safe_constantize ||
      "#{cls.base_class}::WorkflowJob".safe_constantize ||
      Model::WorkflowJob
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods

    include Record::Steppable
    include Record::Updatable::ClassMethods

    # =========================================================================
    # :section: Record::Steppable overrides
    # =========================================================================

    public

    # Workflow state table.
    #
    # @param [Model, Class<Model>, nil] item      Default: self.
    #
    # @return [Hash]
    #
    def state_table(item = nil)
      item and super or @state_table ||= super(self)
    end

    # Workflow state configuration.
    #
    # @param [Model, Class<Model>, nil] item      Default: self.
    # @param [Boolean]                  no_raise
    #
    # @return [Hash, nil]
    #
    def get_state_table(item = nil, no_raise: true)
      # noinspection RubyMismatchedArgumentType
      super((item || self), no_raise: no_raise)
    end

    # All valid workflow states.
    #
    # @param [Model, Class<Model>, nil] item
    #
    # @return [Array<Symbol>]
    #
    def get_state_names(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # =========================================================================
    # :section: Record::Steppable overrides
    # =========================================================================

    public

    # Return the class from app/jobs associated with the record class.
    #
    # @param [Model, Class<Model>, nil] item  Default: self.
    #
    # @return [Class<Model::WorkflowJob>]
    #
    def job_class(item = nil)
      item and super or @job_class ||= super(self)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Called from the including class to generate query- and action-methods
    # associated with the column.
    #
    # @param [Array<Symbol,String>, nil] states   Default: #get_state_names
    #
    # @return [void]
    #
    # == Usage Notes
    # If the including class has defined a STATE_TABLE or STATEs constant prior
    # to including this module, this method will be invoked implicitly using
    # that set of state values.  Otherwise, this method will have be invoked
    # explicitly after the state table has been defined.
    #
    def generate_state_methods(states = nil)
      states ||= get_state_names
      enum_methods(state_column => states) if states.present?
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Validate state table definitions and interconnections.
    #
    # @param [Hash, nil] table   Def: `#state_table`
    #
    # == Usage Notes
    # This is best put at the very end of the class definition so that any
    # methods specified in the table definitions will have been defined.
    #
    #--
    # noinspection RubyNilAnalysis
    #++
    def validate_state_table(table = nil)
      table ||= get_state_table(no_raise: false)
      meths  = self.is_a?(Module) ? instance_methods : self.class.methods
      states = table.keys
      errors = []
      table.each_pair do |state, config|

        # == Check optional note
        if config.key?(:note)
          item = "#{state}[:note]"
          note = config[:note]
          if !note.is_a?(Proc) && !note.is_a?(Symbol) && !note.is_a?(String)
            errors << "#{item}: invalid class #{note.class}"
          elsif note.is_a?(Symbol) && !meths.include?(note)
            errors << "#{item}: invalid method #{note.inspect}"
          end
        end

        # == Check optional method
        if config.key?(:meth)
          item = "#{state}[:meth]"
          meth = config[:meth]
          if !meth.is_a?(Proc) && !meth.is_a?(Symbol)
            errors << "#{item}: invalid class #{meth.class}"
          elsif meth.is_a?(Symbol) && !meths.include?(meth)
            errors << "#{item}: invalid method #{meth.inspect}"
          end
        end

        # == Check next states
        item = "#{state}[:next]"
        next_states = config[:next]
        if !config.key?(:next)
          errors << "#{item} missing"
        elsif next_states.is_a?(FalseClass)
          # Valid terminal state.
        elsif !next_states.is_a?(Array) && !next_states.is_a?(Symbol)
          errors << "#{item} invalid class #{next_states.class}"
        elsif next_states.blank?
          errors << "#{item} empty"
        else
          (Array.wrap(next_states) - states).each do |invalid|
            errors << "#{item}: invalid state #{invalid.inspect}"
          end
        end

      end
      raise errors.join("; \n") if errors.present?
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Create an ActiveJob serializer for the given Record class if it does not
    # already exist.
    #
    # @param [Class, Module, Any] base
    #
    # @return [void]
    #
    def generate_job_serializer(base)
      unless model_class?(base)
        return Log.debug { "#{__method__}: ignoring #{base.class} argument" }
      end
      model_type = base.name
      serializer = "#{model_type}::Serializer"
      return if safe_const_get(serializer)

      base.module_eval <<~HERE_DOC

        class #{serializer} < ActiveJob::Serializers::ObjectSerializer

          def serialize(item)
            super(item.fields)
          end

          def deserialize(hash)
            fields = hash.map { |k, v| [k.to_sym, deserialize(v)] }.to_h
            klass.new(**fields)
          end

          private

          def klass
            #{model_type}
          end

        end
  
        Rails.application.config.active_job.custom_serializers ||= []
        Rails.application.config.active_job.custom_serializers << #{serializer}

      HERE_DOC

      # NOTE: Under normal circumstances custom_serializers will already exist.
      #   This extra check is just for the sake of executing a single file via
      #   "rails runner" from the desktop.

    end

  end

  # Instance methods to be added to the including record class.
  #
  module InstanceMethods

    include Emma::Common

    include Record::Steppable
    include Record::Reportable

    # =========================================================================
    # :section: Record::Steppable overrides
    # =========================================================================

    public

    # Workflow state table associated with the current record.
    #
    # @param [Model, Class<Model>, nil] item  Default: self.
    #
    # @return [Hash]
    #
    def state_table(item = nil)
      # noinspection RubyMismatchedArgumentType
      item and super or @state_table ||= super(self)
    end

    # Workflow state configuration associated with the current record.
    #
    # @param [Model, Class<Model>, nil] item      Default: self.
    # @param [Boolean]                  no_raise
    #
    # @return [Hash, nil]
    #
    def get_state_table(item = nil, no_raise: true)
      # noinspection RubyMismatchedArgumentType
      super((item || self), no_raise: true)
    end

    # All valid workflow states for the current record.
    #
    # @param [Model, Class<Model>, nil] item      Default: self.
    #
    # @return [Array<Symbol>, nil]
    #
    def get_state_names(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # =========================================================================
    # :section: Record::Steppable overrides
    # =========================================================================

    public

    # Cast value in a form for comparison.
    #
    # @param [Model, Symbol, String, nil] item  Default: `self`.
    #
    # @return [Symbol, nil]
    #
    def state_value(item = nil)
      super(item || self[state_column])
    end

    # Get the configured descriptive note for the current state.
    #
    # @param [Model, Symbol, String, nil] item  Default: `self`.
    #
    # @return [String, nil]
    #
    def state_note(item = nil)
      super(item || self[state_column])
    end

    # Get a natural-language description for the current state.
    #
    # @param [Model, Symbol, String, nil] item  Default: `self[STATE_COLUMN]`.
    #
    # @return [String, nil]
    #
    def state_description(item = nil)
      super(item || self[state_column])
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether this record represents an existing EMMA entry.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def existing_entry?(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # Indicate whether this record represents an existing EMMA entry.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def new_submission?(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # =========================================================================
    # :section: Record::Steppable overrides
    # =========================================================================

    public

    # Return the state group of the record.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def state_group(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # Return the label for the state group of the record.
    #
    # @param [Model, String, Symbol, nil] group   Default: `self`.
    #
    # @return [String]
    # @return [nil]                     If *group* is invalid.
    #
    def state_group_label(group = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # =========================================================================
    # :section: Record::Steppable overrides
    # =========================================================================

    public

    # Indicate whether this record is involved in a workflow step related to
    # the creation of a new EMMA entry.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def being_created?(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # Indicate whether this record is involved in a workflow step related to
    # the modification of an existing EMMA entry.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def being_modified?(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # Indicate whether this record is involved in a workflow step related to
    # the removal of an existing EMMA entry.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def being_removed?(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # Indicate whether this record is involved in a workflow step related to
    # the review process.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def under_review?(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # Indicate whether this record is involved in a workflow step related to
    # transmission to a member repository.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def being_submitted?(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # Indicate whether this record is involved in a workflow step related to
    # ingest into the EMMA Unified Index.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def being_indexed?(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # Indicate whether this record is involved in a workflow step related to
    # ingest into the EMMA Unified Index.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def completed?(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # Indicate whether this record is involved in a workflow step which leads
    # to a change in the associated EMMA index entry.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def in_process?(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # Indicate whether this record is involved in a workflow step where
    # non-administrative data (EMMA or file data) could be changed.
    #
    # @param [Model, String, Symbol, nil] item  Default: `self`.
    #
    def unsealed?(item = nil)
      # noinspection RubyMismatchedArgumentType
      super(item || self)
    end

    # =========================================================================
    # :section: Record::Steppable overrides
    # =========================================================================

    public

    # Return the class from app/jobs associated with the record class.
    #
    # @param [Model, Class<Model>, nil] item  Default: self.
    #
    # @return [Class<Model::WorkflowJob>]
    #
    def job_class(item = nil)
      # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
      item and super or @job_class ||= super(self)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get the next legal state(s).
    #
    # If "emma.state_table.[...].next" is *false*, *nil* or missing, the result
    # is an empty array (indicating a terminal state).
    #
    # @param [Symbol, String, nil] curr_state   Passed to #state_value.
    #
    # @return [Array<Symbol>]
    #
    def transitions(curr_state = nil, **)
      curr_state  = state_value(curr_state)
      next_states = state_table.dig(curr_state, :next)
      Array.wrap(next_states).compact_blank
    end

    # Get the next legal state.
    #
    # @param [Symbol, String, nil] curr_state   Passed to #transitions.
    #
    # @return [Symbol, nil]
    #
    def next_state(curr_state = nil, **)
      transitions(curr_state).first.presence
    end

    # Indicate whether the value represents a terminal state.
    #
    # @param [Symbol, String, nil] curr_state  Passed to #transitions.
    #
    def final_state?(curr_state = nil, **)
      next_state(curr_state).blank?
    end

    # Indicate whether the current record can transition to the given state.
    #
    # @param [Symbol, String] new_state
    #
    def can_transition_to?(new_state, **)
      curr_state = state_value
      new_state  = state_value(new_state)
      # noinspection RubyMismatchedArgumentType
      (curr_state == new_state) || transitions(curr_state).include?(new_state)
    end

    # Indicate whether the current record can't transition to the given state.
    #
    # @param [Symbol, String] new_state
    #
    def cannot_transition_to?(new_state, **)
      !can_transition_to?(new_state)
    end

    # Transition to a new state.
    #
    # @param [Symbol, String] new_state
    # @param [Symbol]         meth        For error messages.
    # @param [Boolean]        no_raise    If *false* raise on error.
    #
    # @raise [Record::SubmitError]    If !*no_raise* and invalid transition.
    #
    # @return [nil]                   If *no_raise* and invalid transition.
    # @return [Symbol]                The state before the transition.
    #
    def transition_to(new_state, meth: nil, no_raise: nil, **)
      curr_state = state_value
      new_state  = state_value(new_state)
      unless curr_state == new_state
        next_states = transitions(curr_state)
        # noinspection RubyMismatchedArgumentType
        error =
          if next_states.blank?
            "#{curr_state} is terminal"
          elsif !next_states.include?(new_state)
            "next states #{next_states.inspect}"
          end
        if error
          meth ||= "#{self.class}##{__method__}"
          error = "#{meth}: '#{curr_state}->#{new_state}' is invalid: #{error}"
          Log.warn(error)
          false?(no_raise) and failure(error) or return
        end
        send("#{new_state}!")
      end
      curr_state
    end

    # For each state/action pair of the sequence, transition to the state and
    # perform the action.  An action which is not a proc or a the name of a
    # method then it represents the end of the sequence and the value is used
    # as the return value of this method.
    #
    # @param [Hash{Symbol=>Proc,Symbol,Boolean}, nil] sequence
    # @param [Symbol] meth            For error reporting.
    #
    # @raise [Record::SubmitError]    If !*no_raise* and invalid transition.
    #
    # @return [Boolean]
    #
    # @yield To supply additional state/action pairs.
    # @yieldreturn [Hash{Symbol=>Proc,Symbol,Boolean}]
    #
    def transition_sequence(sequence: nil, meth:, **)
      result = nil
      steps  = sequence || {}
      steps  = steps.merge(yield.to_hash) if block_given?
      steps.each_pair do |new_state, action|
        if cannot_transition_to?(new_state)
          result = nil
          Log.error { "#{meth}: #{__method__}: bad steps: #{steps.inspect}" }
          break
        elsif action.is_a?(Proc) || action.is_a?(Symbol)
          result, new_state = execute_step(action, new_state)
          transition_to(new_state) if new_state
          break if result.nil?
        elsif !action.nil?
          result = action
          transition_to(new_state)
          break
        end
      end
      !!result
    end

    # Execute a sequence step.
    #
    # @param [Proc, Symbol] step        Action to perform.
    # @param [Symbol, nil]  new_state   Target state after *action*.
    # @param [Boolean]      auto_retry
    #
    # @return [Array<(Any,Symbol)>]     Action result and new effective state.
    #
    # == Usage Notes
    # Ensures that if the action raises an exception then that is captured in
    # the instance's :report column.
    #
    def execute_step(step, new_state = nil, auto_retry: false, **)
      # noinspection RubyUnusedLocalVariable
      result = aborting = no_state = nil
      begin
        initial  = state_value
        result   = step.is_a?(Proc) ? step.call : send(step)
        no_state = (state_value != initial) # The action already set the state.
        aborting = failed?
      rescue => error
        aborting = true
        set_error(error)
        # noinspection RubyMismatchedArgumentType
        set_exec_report(error)
      end
      if aborting
        case self
          when Action
            self.state     = auto_retry ? :started : :aborted
            self.command   = :retry if auto_retry
            self.condition = :failed
          when Phase
            self.state     = auto_retry ? :restarting : :aborted
          else
            Log.warn { "#{__method__}: #{self.class} unexpected" }
        end
        save
      end
      new_state = nil if no_state || aborting # State already set.
      return result, new_state
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Schedule a method to be run asynchronously (unless :async is *false*).
    #
    # @param [Symbol]  meth
    # @param [Array]   args           Arguments to *meth*.
    # @param [Boolean] async          If *false* do not run asynchronously.
    # @param [Hash]    opt
    #
    # @return [Boolean]               False if the job could not be processed.
    #
    def job_run(meth, *args, async: true, **opt)
      async = false # TODO: remove when implementing async jobs
      if false?(async)
        job_class.perform_now(self, meth, *args, **opt)
        exec_report.blank?
      else
        job_class.perform_later(self, meth, *args, **opt).present?
      end
    end

    # If the option hash includes a :callback then invoke it.
    #
    # @param [Hash] opt               Passed to #cb_schedule.
    #
    # @return [Boolean]               False if the job could not be processed.
    #
    def run_callback(**opt)
      callback     = opt.delete(:callback) or return true
      meth         = opt.delete(:meth) || calling_method
      opt[:from] ||= self
      __debug_items("#{self.class}::#{meth}", __method__) do
        { from: opt[:from], callback: callback }
      end
      callback.cb_schedule(**opt)
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

    include InstanceMethods

    generate_state_methods
    generate_job_serializer(base)

  end

end

__loading_end(__FILE__)
