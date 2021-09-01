# lib/sim/models/upload_workflow/single.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# These overrides are segregated from the normal code to make them easier to
# hide from Yard when generating documentation.

__loading_begin(__FILE__)

require_relative '../../../../app/models/upload_workflow/single'

# =============================================================================
# :section: Core
# =============================================================================

public

module UploadWorkflow::Single::Simulation

  include UploadWorkflow::Single::Data

  # ===========================================================================
  # :section: Classes
  # ===========================================================================

  public

  # Stand-in for Upload properties.
  #
  # @!attribute [rw] item
  #   @return [Upload, Hash, nil]
  #
  # @!attribute [rw] file_valid
  #   @return [Boolean]
  #
  # @!attribute [rw] metadata_valid
  #   @return [Boolean]
  #
  # @!attribute [rw] emma_item
  #   @return [Boolean]
  #
  # @!attribute [rw] items
  #   @return [Array]
  #
  # @!attribute [rw] succeeded
  #   @return [Array]
  #
  # @!attribute [rw] failed
  #   @return [Array]
  #
  # @!attribute [rw] params
  #   @return [Upload, Hash, String, Array, nil]
  #
  # @!attribute [rw] data
  #   @return [Upload, Hash]
  #
  # @!attribute [rw] id
  #   @return [String, Upload, nil]
  #
  # @!attribute [rw] invalid_file
  #   @return [Boolean, nil]
  #
  # @!attribute [rw] invalid_entry
  #   @return [Boolean, nil]
  #
  # @!attribute [rw] db_failure
  #   @return [Boolean, nil]
  #
  # @!attribute [rw] no_review
  #   @return [Boolean, nil]
  #
  # @!attribute [rw] no_reviewers
  #   @return [Boolean, nil]
  #
  # @!attribute [rw] auto_review
  #   @return [Boolean, nil]
  #
  # @!attribute [rw] auto_approve
  #   @return [Boolean, nil]
  #
  # @!attribute [rw] auto_reject
  #   @return [Boolean, nil]
  #
  # @!attribute [rw] auto_submit
  #   @return [Boolean, nil]
  #
  # @!attribute [rw] auto_cancel
  #   @return [Boolean, nil]
  #
  class RecordProperties

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Generated/retrieved Upload record.
    #
    # @return [Upload, Hash, nil]
    #
    attr_accessor :item

    # Indicates that the item has a valid file.
    #
    # @return [Boolean]
    #
    attr_accessor :file_valid

    # Indicates that the item has valid metadata.
    #
    # @return [Boolean]
    #
    attr_accessor :metadata_valid

    # Whether the submission should be consider EMMA-native.
    #
    # @return [Boolean]
    #
    attr_accessor :emma_item

    # Original items.
    #
    # @return [Array]
    #
    attr_accessor :items

    # Original supplied data parameters.
    #
    # @return [Upload, Hash, String, Array, nil]
    #
    attr_accessor :params

    # Parameter for :upload_create
    #
    # @return [Upload, Hash]
    #
    attr_accessor :data

    # Parameter for :upload_edit
    #
    # @return [String, Upload, nil]
    #
    attr_accessor :id

    alias_method :emma_items, :emma_item

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Properties used to drive simulated behavior.
    #
    # @type [Hash{Symbol=>Boolean,Integer}]
    #
    PROPERTY = UploadWorkflow::Simulation::PROPERTY

    # Simulation property settings.
    #
    # @type [Array<Symbol>]
    #
    #--
    # noinspection LongLine
    #++
    PROP_NAME = [
      :invalid_file,  # The file associated with the submission should be considered invalid.
      :invalid_entry, # The metadata associated with the submission should be considered invalid.
      :db_failure,    # Whether a simulated database failure should occur.
      :no_review,     # Whether a review is not required.
      :no_reviewers,  # Whether reviewer(s) appear to be unavailable initially.
      :auto_review,   # Whether the SYSTEM can perform an automated review on the submission.
      :auto_approve,  # Whether a simulated REVIEWER approval should be automatically applied.
      :auto_reject,   # Whether a simulated REVIEWER rejection should be automatically applied.
      :auto_submit,   # Whether a simulated USER submit should be automatically applied.
      :auto_cancel,   # Whether a simulated USER cancel should be automatically applied.
    ].freeze

    PROP_NAME.each do |prop|

      attr_accessor(prop)

      # Each property will return a value only the first time it is accessed
      # and then *nil* thereafter (until it is provided another value).
      module_eval <<~HEREDOC
        def #{prop}
          @#{prop}.tap { @#{prop} = nil }
        end
      HEREDOC

    end

    # Initial property settings specific to the workflow simulation branch.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    PROP_SETTING = {
      common: PROP_NAME.map { |prop| [prop, PROPERTY[prop]] }.to_h,
      create: {
        emma_item:     PROPERTY[:upsert_emma_items],
        invalid_file:  PROPERTY[:invalid_file],
        invalid_entry: PROPERTY[:invalid_entry],
        db_failure:    PROPERTY[:db_failure],
        no_review:     PROPERTY[:no_review],
      },
      edit: {
        emma_item:     PROPERTY[:upsert_emma_items],
        invalid_file:  PROPERTY[:edit_invalid_file],
        invalid_entry: PROPERTY[:edit_invalid_entry],
        db_failure:    PROPERTY[:edit_db_failure],
        no_review:     PROPERTY[:edit_no_review],
      },
      remove: {
        emma_item:     PROPERTY[:remove_emma_items],
        auto_submit:   PROPERTY[:auto_remove_submit],
        auto_cancel:   PROPERTY[:auto_remove_cancel]
      }
    }.deep_freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a new instance.
    #
    # @param [Upload, Hash, String, Array, nil] params
    #
    def initialize(params = nil)
      set_params(params)
      set_simulation
    end

    # set_params
    #
    # @param [Upload, Hash, String, Array, nil] params
    #
    def set_params(params = nil)
      @params = params
      @items  = @data = @id = nil
      # noinspection RubyCaseWithoutElseBlockInspection
      case @params
        when Array  then @items = @params
        when Upload then @data  = @params
        when Hash   then @data  = @params
        when String then @id    = @params
      end
      @items ||= []
      @data  ||= {}
      @id    ||= @data[:id]
    end

    # Apply simulation settings based on the primary workflow type.
    #
    # @param [Symbol] type
    #
    def set_simulation(type = :create)
      settings = PROP_SETTING[:common]
      if (type_settings = PROP_SETTING[type])
        settings = settings.merge(type_settings)
      else
        __debug("#{__method__}: #{type.inspect}: invalid type")
      end
      settings.each_pair { |prop, value| send("#{prop}=", value) }
    end

    # set_item
    #
    # @param [Upload, Hash, nil] values
    #
    def set_item(values = nil)
      @file_valid     = false
      @metadata_valid = false
      @item           = (values || data).dup
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def empty?
      item.blank?
    end

    def file_valid?
      file_valid.present?
    end

    def metadata_valid?
      metadata_valid.present?
    end

    def complete?
      file_valid? && metadata_valid?
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Set simulated record properties.
  #
  # @param [*] data
  #
  # @return [RecordProperties]
  # @return [nil]                   If `#simulating` is *false*.
  #
  def set_submission(data)
    return (@submission = nil) unless simulating
    reset_status if respond_to?(:reset_status)
    @submission = RecordProperties.new(data)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # Workflow methods to be augmented so that they report on :submission
  # instead of :record.
  #
  # @type [Array<Symbol>]
  #
  OVERRIDE_WORKFLOW_METHODS =
    [UploadWorkflow::Single::Data, Workflow::Base::Data].flat_map { |mod|
      mod.public_instance_methods(false).select { |m| m.end_with?('?') }
    }.compact.uniq.freeze

  # Override workflow methods defined in terms of the Upload :record to check
  # the simulated submission.
  #
  # @param [Module] base
  #
  # @see #OVERRIDE_WORKFLOW_METHODS
  #
  def self.included(base)
    return unless base < Workflow::Base
    base.class_eval do
      OVERRIDE_WORKFLOW_METHODS.each do |m|
        define_method(m) do
          # noinspection RubyArgCount
          super() || (submission.try(m) if simulating)
        end
      end
    end
  end

end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Single::Events

  # =========================================================================
  # :section: UploadWorkflow::Events overrides
  # =========================================================================

  public

  # The user initiates submission of a new entry.
  def create(*)
    super.tap do
      submission.set_simulation(__method__) if simulating
    end
  end

  # The user initiates modification of an existing entry.
  def edit(*)
    super.tap do
      submission.set_simulation(__method__) if simulating
    end
  end

  # The user initiates removal of an existing entry.
  def remove(*)
    super.tap do
      submission.set_simulation(__method__) if simulating
    end
  end

  # The system is resetting the workflow state.
  def reset(*)
    super.tap do
      # noinspection RailsParamDefResolve
      try(:initialize_state, submission.params, **{}) if simulating
    end
  end

end

__loading_end(__FILE__)
