# app/models/concerns/record/steppable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common methods for ActiveRecord classes that are used to track outcomes
# across multiple steps.
#
# NOTE: This was originally part of a refactoring to support asynchronous
#   submission workflows.  Although that approach has been abandoned, this is
#   being retained in commented-out form for possible use in a refactoring of
#   the Upload class that would include removal of the "workflow" gem.
#
# #@!attribute [rw] state
#  #Database :state column.
#  #@return [String]
#
# === Usage Notes
# If the including class does not define a STATE_TABLE constant before the
# include of this module, #generate_state_methods will need to be run
# explicitly with a Hash with state values as keys.
#
module Record::Steppable
=begin # NOTE: preserved for possible future use

  extend ActiveSupport::Concern

  include Record
  include Record::Searchable

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default state column name.
  #
  # @type [Symbol]
  #
  # @note From Upload::WorkflowMethods#STATE_COLUMNS
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
  # @see file:config/locales/state_table.en.yml
  #
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

  # Groupings of states related by theme.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/controllers/upload.en.yml
  #
  # @note From Upload::WorkflowMethods#STATE_GROUP
  #
  STATE_GROUP =
    I18n.t('emma.upload.state_group', default: {}).transform_values { |entry|
      states = Array.wrap(entry[:states]).map(&:to_sym)
      entry.merge(states: states)
    }.deep_freeze

  # Mapping of workflow state to category.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # @note From Upload::WorkflowMethods#REVERSE_STATE_GROUP
  #
  REVERSE_STATE_GROUP =
    STATE_GROUP.flat_map { |group, entry|
      entry[:states].map { |state| [state,  group] }
    }.sort.to_h.freeze

  # ===========================================================================
  # :section: Record::Searchable overrides
  # ===========================================================================

  public

  # The database column currently associated with the workflow state of the
  # record.
  #
  # @return [Symbol]
  #
  # @note From Upload::WorkflowMethods#state_column
  #
  def state_column(*)
    STATE_COLUMN
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
  # @param [Boolean]             fatal
  #
  # @return [Hash, nil]
  #
  def get_state_table(item, fatal: false)
    return unless item
    cls = self_class(item)
    # noinspection RubyResolve
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
    raise error if fatal
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
  # @note From Upload::WorkflowMethods#existing_entry?
  #
  def existing_entry?(item)
    state_value(item) == :completed
  end

  # Indicate whether this record represents a submission that has not yet
  # become an EMMA entry.
  #
  # @param [Model, String, Symbol, nil] item
  #
  # @note From Upload::WorkflowMethods#new_submission?
  #
  def new_submission?(item)
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
  # @note From Upload::WorkflowMethods#state_group
  #
  def state_group(item)
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
  # @note From Upload::WorkflowMethods#state_group_label
  #
  def state_group_label(group)
    if group.is_a?(String) || group.is_a?(Symbol)
      group = group.to_sym
    else
      group = state_group(group)
      group = nil if group == :all
    end
    # noinspection RubyMismatchedArgumentType
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
  # @note From Upload::WorkflowMethods#being_created?
  #
  def being_created?(item)
    state_group(item) == :create
  end

  # Indicate whether this record is involved in a workflow step related to
  # the modification of an existing EMMA entry.
  #
  # @param [Model, String, Symbol, nil] item
  #
  # @note From Upload::WorkflowMethods#being_modified?
  #
  def being_modified?(item)
    state_group(item) == :edit
  end

  # Indicate whether this record is involved in a workflow step related to
  # the removal of an existing EMMA entry.
  #
  # @param [Model, String, Symbol, nil] item
  #
  # @note From Upload::WorkflowMethods#being_removed?
  #
  def being_removed?(item)
    state_group(item) == :remove
  end

  # Indicate whether this record is involved in a workflow step related to
  # the review process.
  #
  # @param [Model, String, Symbol, nil] item
  #
  # @note From Upload::WorkflowMethods#under_review?
  #
  def under_review?(item)
    state_group(item) == :review
  end

  # Indicate whether this record is involved in a workflow step related to
  # transmission to a member repository.
  #
  # @param [Model, String, Symbol, nil] item
  #
  # @note From Upload::WorkflowMethods#being_submitted?
  #
  def being_submitted?(item)
    state_group(item) == :submission
  end

  # Indicate whether this record is involved in a workflow step related to
  # ingest into the EMMA Unified Index.
  #
  # @param [Model, String, Symbol, nil] item
  #
  # @note From Upload::WorkflowMethods#being_indexed?
  #
  def being_indexed?(item)
    state_group(item) == :finalization
  end

  # Indicate whether this record is involved in a workflow step related to
  # ingest into the EMMA Unified Index.
  #
  # @param [Model, String, Symbol, nil] item
  #
  # @note From Upload::WorkflowMethods#completed?
  #
  def completed?(item)
    state_group(item) == :done
  end

  # Indicate whether this record is involved in a workflow step which leads to
  # a change in the associated EMMA Unified Index entry.
  #
  # @param [Model, String, Symbol, nil] item
  #
  # @note From Upload::WorkflowMethods#in_process?
  #
  def in_process?(item)
    item = state_group(item)
    being_submitted?(item) || being_indexed?(item)
  end

  # Indicate whether this record is involved in a workflow step where
  # non-administrative data (EMMA or file data) could be changed.
  #
  # @param [Model, String, Symbol, nil] item
  #
  # @note From Upload::WorkflowMethods#unsealed?
  #
  def unsealed?(item)
    item = state_group(item)
    being_created?(item) || being_modified?(item) || being_removed?(item)
  end

  # Indicate whether this record is *not* involved in a workflow step where
  # non-administrative data (EMMA or file data) could be changed.
  #
  # @param [Model, String, Symbol, nil] item
  #
  # @note From Upload::WorkflowMethods#sealed?
  #
  def sealed?(item)
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
    cls = self_class(item)
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
    # @param [Boolean]                  fatal
    #
    # @return [Hash, nil]
    #
    def get_state_table(item = nil, fatal: false)
      # noinspection RubyMismatchedArgumentType
      super((item || self), fatal: fatal)
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
    # === Usage Notes
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
    # === Usage Notes
    # This is best put at the very end of the class definition so that any
    # methods specified in the table definitions will have been defined.
    #
    def validate_state_table(table = nil)
      table ||= get_state_table(fatal: true)
      meths  = self.is_a?(Module) ? instance_methods : self.class.methods
      states = table.keys
      errors = []
      table.each_pair do |state, config|

        # === Check optional note
        if config.key?(:note)
          item = "#{state}[:note]"
          note = config[:note]
          if !note.is_a?(Proc) && !note.is_a?(Symbol) && !note.is_a?(String)
            errors << "#{item}: invalid class #{note.class}"
          elsif note.is_a?(Symbol) && !meths.include?(note)
            errors << "#{item}: invalid method #{note.inspect}"
          end
        end

        # === Check optional method
        if config.key?(:meth)
          item = "#{state}[:meth]"
          meth = config[:meth]
          if !meth.is_a?(Proc) && !meth.is_a?(Symbol)
            errors << "#{item}: invalid class #{meth.class}"
          elsif meth.is_a?(Symbol) && !meths.include?(meth)
            errors << "#{item}: invalid method #{meth.inspect}"
          end
        end

        # === Check next states
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
      base_name  = base.name
      serializer = "#{base_name}::Serializer"
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
            #{base_name}
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
  #--
  # noinspection RubyTooManyMethodsInspection
  #++
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
    # @param [Boolean]                  fatal
    #
    # @return [Hash, nil]
    #
    def get_state_table(item = nil, fatal: false)
      # noinspection RubyMismatchedArgumentType
      super((item || self), fatal: fatal)
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
    # @param [Model, Symbol, String, nil] item  Default: `self[state_column]`.
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
    # to a change in the associated EMMA Unified Index entry.
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
      # noinspection RubyMismatchedArgumentType
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
=end
end

__loading_end(__FILE__)
