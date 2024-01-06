# app/models/concerns/model.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common model methods.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module Model

  extend ActiveSupport::Concern

  include Emma::Constants

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A unique identifier for this model instance.
  #
  # @return [String]
  #
  def identifier
    (respond_to?(:id) ? id : object_id).to_s
  end

  # Indicate whether *name* is a field defined by this model.
  #
  # @param [Symbol, String, *]
  #
  def include?(name)
    field_names.include?(name&.to_sym)
  end

  # The fields defined by this model.
  #
  # @return [Array<Symbol>]
  #
  def field_names
    if is_a?(ApplicationRecord)
      attribute_names.map(&:to_sym).sort
    else
      instance_variables.map { |v| v.to_s.delete_prefix('@').to_sym }.sort
    end
  end

  # The data fields defined by this model plus synthetic field values.
  #
  # @return [Array<Symbol>]
  #
  def synthetic_field_names
    return [] unless respond_to?(:model_type)
    Model.config_for(model_type).synthetic.keys.tap do |meths|
      attrs = field_names
      meths << :user if attrs.include?(:user_id)
      meths << :org  if attrs.include?(:org_id)
    end
  end

  # The data fields defined by this model plus synthetic fields.
  #
  # @return [Array<Symbol>]
  #
  def extended_field_names
    field_names + synthetic_field_names
  end

  # The fields and values for this model instance.
  #
  # @param [Array<Symbol>] only       Only these names if provided.
  #
  # @return [Hash{Symbol=>*}]
  #
  def fields(*only)
    only = only.compact.presence&.map(&:to_sym)
    if is_a?(ApplicationRecord)
      attributes.symbolize_keys.tap { |hash| hash.slice!(*only) if only }
    else
      names = field_names
      names = names.intersection(only) if only
      names.map { |meth| [meth, send(meth)] if respond_to?(meth) }.compact.to_h
    end
  end

  # The data and synthetic fields/values for this model instance.
  #
  # @param [Array<Symbol>] only       Only these names if provided.
  #
  # @return [Hash{Symbol=>*}]
  #
  def synthetic_fields(*only)
    only  = only.compact.presence&.map(&:to_sym)
    meths = synthetic_field_names
    meths = meths.intersection(only) if only.present?
    meths.map { |meth| [meth, send(meth)] if respond_to?(meth) }.compact.to_h
  end

  # The data and synthetic fields/values for this model instance.
  #
  # @param [Array<Symbol>] only       Only these names if provided.
  #
  # @return [Hash{Symbol=>*}]
  #
  def extended_fields(*only)
    values = fields(*only)
    synth  = synthetic_fields(*only)
    values.merge(synth)
  end

  # The fields and values for this instance as a Hash.
  #
  # @return [Hash{Symbol=>*}]
  #
  def to_h(**)
    extended_fields
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Get configured record fields for a model/controller.
  #
  # @param [Symbol, String, Class, Model, *] type   Model/controller type
  # @param [Boolean]                         fatal
  #
  # @raise [RuntimeError]             If *type* does not map on to a model.
  #
  # @return [ModelConfig]             Frozen result.
  # @return [nil]                     Only if *fatal* is *false*.
  #
  def self.configuration_fields(type, fatal: true)
    if !(arg = type).is_a?(Symbol) && !(type = model_for(type))
      error = "#{arg}: not a model type"
    elsif fields_table[type]
      return fields_table[type]
    elsif (config = configured_fields_for(type)).blank?
      error = "#{arg}: no configuration"
    else
      config.validate(type: type) if DEBUG_CONFIGURATION
      return fields_table[type] = config.deep_freeze
    end
    Log.warn { "#{__method__}: #{error}" }
    raise error if fatal
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  protected

  # Keys under "emma.*.record" beginning with an underscore, which represent
  # the control directive for specifying the base configuration.
  #
  # @type [Array<Symbol>]
  #
  BASE_DIRECTIVE = %i[base base_config base_configuration].freeze

  # Keys under "emma.*.record" beginning with an underscore, which define
  # display fields which are filled dynamically.
  #
  # @type [Array<Symbol>]
  #
  SYNTHETIC_FIELDS = %i[synthetic].freeze

  # Keys under "emma.*.record" beginning with an underscore, which do not map
  # on to actual database columns.
  #
  # @type [Array<Symbol>]
  #
  DIRECTIVES = (BASE_DIRECTIVE + SYNTHETIC_FIELDS).freeze

  # Configured record fields for each model/controller.
  #
  # @return [Hash{Symbol=>ModelConfig}]
  #
  def self.fields_table
    # noinspection RbsMissingTypeSignature
    @fields_table ||= {}
  end

  # Combine configuration settings for a given model/controller.
  #
  # @param [Symbol, String] type
  #
  # @return [ModelConfig]
  #
  def self.configured_fields_for(type)
    model_config = I18n.t("emma.#{type}", default: nil)&.deep_dup || {}

    # Start with definitions from config/locales/records/*.yml, separating
    # control directives from field name entries.
    directives = {}
    all_fields =
      (model_config[:record] || {}).map { |field, prop|
        name = field.to_s.sub!(/^_/, '')&.to_sym
        if name && DIRECTIVES.include?(name)
          directives[name] = prop
        elsif name
          Log.warn { "#{__method__}(#{type}): #{name}: unexpected directive" }
        end
        [field, Field.normalize(prop, field)] unless name
      }.compact.to_h

    # Special handling so that "emma.search.record" entries are initialized
    # with the equivalent values from the submission record configuration.
    if (base = directives.values_at(*BASE_DIRECTIVE).first).present?
      base = base.values_at(:record, :field) if base.is_a?(Hash)
      base_config, base_field = Array.wrap(base).map(&:to_sym)
      base_config = config_for(base_config)&.dig(:all, base_field) || {}
      all_fields.each_pair do |field, prop|
        all_fields[field] = base_config[field].deep_merge(prop)
      end
    end

    # Add definitions of fields which do not map on to data columns.
    synthetic = directives.values_at(*SYNTHETIC_FIELDS).first || {}
    synthetic.each_pair do |field, prop|
      all_fields[field] = Field.normalize(prop, field).merge!(synthetic: true)
    end

    # Apply adjustments from config/locales/controllers/*.yml then finalize
    # the generic entries.
    display_config!(all_fields, model_config[:display_fields])
    all_fields.transform_values! { |prop| Field.finalize!(prop) }

    # Add entries for each page with its own :display_fields section.
    controller_configs =
      model_config.map { |action, section|
        next unless section.is_a?(Hash)
        next unless (display_fields = section[:display_fields])
        action_fields = display_config!(all_fields.deep_dup, display_fields)
        action_fields.transform_values! { |prop| Field.finalize!(prop) }
        [action, action_fields]
      }.compact.to_h

    # Return with the generic field configurations followed by entries for
    # each action-specific field configuration.
    ModelConfig.new(all: all_fields, **controller_configs)
  end

  # For pages that specify their own :display_fields section, *fields* may
  # define the order of fields or simply modify the properties of the fields.
  #
  # If *fields* is a Hash then each key represents a field (*all_fields* key)
  # and one or more property overrides.  Field order is not affected by the
  # ordering of the keys in this case.
  #
  # If *fields* is an Array, each entry represents a field position.  If the
  # entry is a simple String or Symbol then it inherits all properties of the
  # matching *all_fields* entry.  Per Field#normalize, if the entry is a Hash
  # with a String value, the value overrides the fields :label property; if the
  # entry has a Hash value, these are treated as property overrides.
  #
  # @param [Hash]                   all_fields      Baseline field definitions.
  # @param [Hash, Array, :all, nil] display_fields  Field overrides.
  #
  # @return [Hash]                                  The modified *all_fields*.
  #
  def self.display_config!(all_fields, display_fields)
    case display_fields
      when nil, :all
        # No changes *fields* is missing or "!ruby/symbol all" by itself.
        all_fields

      when Array
        # Specifies the field order for all actions for this model, optionally
        # overriding field properties.  If any of the lines is :all, that
        # indicates the inclusion of all fields defined by *action_fields*.
        all = display_fields.index(:all) and display_fields.delete(:all)
        overrides =
          display_fields.map { |line|
            field, prop = line.is_a?(Hash) ? line.first : [line.to_sym, {}]
            prop &&= Field.normalize(prop, field)
            prop &&= all_fields[field]&.deep_merge(prop) || prop
            [field, prop]
          }.to_h
        if all == 0
          # Start with *action_fields* in the provided order; *fields* lines
          # either adjust field properties or add new fields to the end.
          all_fields.merge!(overrides)
        elsif all
          # The *fields* defines the order for all of the fields given.  Any
          # *action_fields* not explicitly referenced are moved to the end.
          remaining = all_fields.keys - overrides.keys
          overrides.merge!(all_fields.slice(*remaining)) if remaining.present?
          all_fields.replace(overrides)
        else
          # The *fields* defines a replacement for the standard action fields;
          # fields not explicitly referenced are not displayed.
          all_fields.replace(overrides)
        end

      when Hash
        # Selective override(s) of field properties without changing the order
        # of the fields.
        overrides =
          display_fields.map { |field, prop|
            prop &&= Field.normalize(prop, field)
            prop &&= all_fields[field]&.deep_merge(prop) || prop
            [field, prop]
          }.to_h
        all_fields.merge!(overrides)

      else
        # No changes if *fields* is invalid.
        Log.warn { "#{__method__}: unexpected: #{display_fields.inspect}" }
        all_fields
    end
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # @private
  CONFIG_PREFIX = /^\s*(en\.)?emma\./

  # Return the model class associated with *item*.
  #
  # @param [Any, nil] item             Symbol, String, Class, Model
  #
  # @return [Class, nil]
  #
  def self.class_for(item)
    item = item.class             if item.is_a?(Model)
    item = item.base_class        if item.respond_to?(:base_class)
    item = namespace_for(item)    if namespaced?(item)
    item = item.to_s              if item.is_a?(Symbol)
    item = item.camelize          if item.is_a?(String)
    item = User                   if item == 'Account'
    item = item.safe_constantize  if item.is_a?(String)
    item                          if item.is_a?(Class)
  end

  # Return the name of the model associated with *item*.
  #
  # @param [Any, nil] item             Symbol, String, Class, Model
  #
  # @return [Symbol, nil]
  #
  def self.model_for(item)
    item = item.to_s                    if item.is_a?(Symbol)
    item = item.remove(CONFIG_PREFIX)   if item.is_a?(String)
    item = class_for(item)
    item = item.name.underscore.to_sym  if item.is_a?(Class)
    item = :account                     if item == :user
    item                                if item.is_a?(Symbol)
  end

  # Return the name of the model associated with *item*.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [Symbol, nil]
  #
  def self.for(item)
    model_for(item)
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  private

  def self.namespace_for(v)
    v.to_s.underscore.split('/').first
  end

  def self.namespaced?(v)
    return false unless v.is_a?(Symbol) || v.is_a?(String) || v.is_a?(Class)
    v.to_s.match?(%r{::|/})
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Get configured record fields for the indicated model/controller.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [ModelConfig]             Frozen result.
  # @return [nil]
  #
  def self.config_for(item)
    configuration_fields(item, fatal: false)
  end

  # Get configured record fields relevant to the given context for the
  # indicated model/controller.
  #
  # @param [Symbol, String, Class, Model, *] item
  # @param [Symbol]                          action
  #
  # @return [ActionConfig, nil]
  #
  def self.context_fields(item, action)
    config = config_for(item) || {}
    config[action&.to_sym]
  end

  # Get configured record fields relevant to an :index action for the indicated
  # model/controller.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [ActionConfig]            Frozen result.
  #
  def self.index_fields(item)
    config = config_for(item) || {}
    config[:index] || config[:all] || ActionConfig::EMPTY
  end

  # Get configured record fields relevant to a :show action for the indicated
  # model/controller.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [ActionConfig]            Frozen result.
  #
  def self.show_fields(item)
    config = config_for(item) || {}
    config[:show] || config[:all] || ActionConfig::EMPTY
  end

  # Get all configured record fields for the indicated model.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [ActionConfig]            Frozen result.
  #
  def self.database_fields(item)
    config = config_for(item) || {}
    config[:database] || config[:all] || ActionConfig::EMPTY
  end

  # Get all configured record fields relevant to a create/update form for the
  # indicated model.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [ActionConfig]            Frozen result.
  #
  def self.form_fields(item)
    database_fields(item)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Methods for the including class or its instances.
  #
  module Methods

    include Emma::Common

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether instances of the including class are composed of other
    # Model instances.
    #
    def aggregate?
      aggregate_type.present?
    end

    # The type for constituent Model elements for a class whose instances are
    # aggregates.
    #
    # @return [Class<Model>, nil]
    #
    def aggregate_type
      self_class.safe_const_get(:BASE_ELEMENT)
    end

    # The field holding constituent Model elements for a class which supports
    # aggregates.
    #
    # @return [Symbol, nil]
    #
    def aggregate_field
      self_class.safe_const_get(:BASE_FIELD)
    end

    # Indicate whether the including class is primarily a container for a list
    # of other Model instances.
    #
    def collection?
      collection_type.present?
    end

    # The type for constituent Model elements for a class whose instances are
    # collections.
    #
    # @return [Class<Model>, nil]
    #
    def collection_type
      self_class.safe_const_get(:LIST_ELEMENT)
    end

    # The field holding constituent Model elements for a class whose instances
    # are collections.
    #
    # @return [Symbol, nil]
    #
    def collection_field
      self_class.safe_const_get(:LIST_FIELD)
    end

    # The constituent Model elements related to this Model instance.
    #
    # @return [Array]   Possibly empty.
    # @return [nil]     If the instance is not an aggregate or collection.
    #
    def elements
      relation_field = [collection_field, aggregate_field].compact.first
      try(relation_field) if relation_field
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get configured record fields relevant to an :index action for the model.
    #
    # @param [Symbol, String, Class, Model, *] item   Default: self
    #
    # @return [ActionConfig]            Frozen result.
    #
    def index_fields(item = nil)
      Model.index_fields(item || self)
    end

    # Get configured record fields relevant to a :show action for the model.
    #
    # @param [Symbol, String, Class, Model, *] item   Default: self
    #
    # @return [ActionConfig]            Frozen result.
    #
    def show_fields(item = nil)
      Model.show_fields(item || self)
    end

    # Get all configured record fields for the model.
    #
    # @param [Symbol, String, Class, Model, *] item   Default: self
    #
    # @return [ActionConfig]            Frozen result.
    #
    def database_fields(item = nil)
      Model.database_fields(item || self)
    end

    # Get all configured record fields relevant to a create/update form for the
    # model.
    #
    # @param [Symbol, String, Class, Model, *] item   Default: self
    #
    # @return [ActionConfig]            Frozen result.
    #
    def form_fields(item = nil)
      Model.form_fields(item || self)
    end

  end

  # Methods which extend the including class.
  #
  module ClassMethods

    include Methods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Create a :LIST_FIELD or :BASE_FIELD constant for a class if it defines
    # :LIST_ELEMENT or :BASE_ELEMENT (respectively).
    #
    # @param [Symbol, String] field_name
    # @param [Class, nil]     field_type
    #
    # @return [Symbol, nil]
    #
    # @see Api::Record::Associations::ClassMethods#has_many
    #
    def set_relation_field(field_name, field_type)
      return unless field_type
      if field_type == collection_type
        self_class.const_set(:LIST_FIELD, field_name.to_sym)
      elsif field_type == aggregate_type
        self_class.const_set(:BASE_FIELD, field_name.to_sym)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Validate the including aggregate/collection class.
    #
    # If a record class is intended to be an aggregate it should both include
    # Api::Shared::AggregateMethods and define :BASE_ELEMENT.
    #
    # If a record class is intended to be a collection it should both include
    # Api::Shared::CollectionMethods and define :LIST_ELEMENT.
    #
    # @raise [SyntaxError]            A problem was detected in development.
    #
    # @return [TrueClass]
    #
    def validate_relations
      a_mod  = ancestors.include?(Api::Shared::AggregateMethods)
      c_mod  = ancestors.include?(Api::Shared::CollectionMethods)
      a_type = aggregate_type
      c_type = collection_type
      both   = nil
      miss   = []
      if a_mod && c_mod
        both = [a_mod, c_mod]
      elsif a_type && c_type
        both = [a_type, c_type]
      else
        miss << :BASE_ELEMENT                   if a_mod  && !a_type
        miss << :LIST_ELEMENT                   if c_mod  && !c_type
        miss << Api::Shared::AggregateMethods   if a_type && !a_mod
        miss << Api::Shared::CollectionMethods  if c_type && !c_mod
      end
      failure =
        if both.present?
          both = both.join(' and ') if both.is_a?(Array)
          "found #{both}: cannot be both an aggregate and a collection"
        elsif miss.present?
          miss.map! { |item|
            item = item.to_s
            kind = item.match?(/BASE|Aggregate/) ? :aggregate : :collection
            "#{kind} record missing #{item}"
          }.join('; AND ')
        end
      if failure.present?
        failure = "BAD RECORD DEFINITION for #{self.name}: #{failure}"
        Log.error(failure)
        raise SyntaxError, failure unless production_deployment?
      end
      true
    end

  end

  # Methods for instances of the including class.
  #
  module InstanceMethods
    include Model
    include Methods
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    include InstanceMethods

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      extend ClassMethods
      # :nocov:
    end

    # =========================================================================
    # :section: ClassMethods overrides
    # =========================================================================

    public

    # Create a :LIST_FIELD or :BASE_FIELD constant for a class if it defines
    # :LIST_ELEMENT or :BASE_ELEMENT (respectively).
    #
    # @param [Symbol, String] field_name
    # @param [Class, nil]     field_type
    #
    # @return [Symbol, nil]
    #
    # @see Api::Record::Associations::ClassMethods#has_many
    #
    def self.set_relation_field(field_name, field_type)
      @check_relations ||= validate_relations
      super
    end

    # =========================================================================
    # :section: InstanceMethods overrides
    # =========================================================================

    public

    # The fields defined by this model.
    #
    # @return [Array<Symbol>]
    #
    def field_names
      @field_names ||= super
    end

    # The data fields defined by this model plus synthetic field values.
    #
    # @return [Array<Symbol>]
    #
    def synthetic_field_names
      @synthetic_field_names ||= super
    end

    # The data fields defined by this model plus synthetic fields.
    #
    # @return [Array<Symbol>]
    #
    def extended_field_names
      @extended_field_names ||= super
    end

  end

end

__loading_end(__FILE__)
