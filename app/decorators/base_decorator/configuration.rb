# app/decorators/base_decorator/configuration.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model/controller related configuration information relative to model_type.
#
module BaseDecorator::Configuration

  include BaseDecorator::Common
  include BaseDecorator::Helpers

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The model associated with the decorator.
  #
  # @return [Symbol]
  #
  # @see BaseDecorator#decorator_for
  #
  def model_type
    must_be_overridden
  end

  # The ActiveRecord subclass associated with the decorator.
  #
  # @return [Class, nil]
  #
  # @see BaseDecorator#decorator_for
  #
  def ar_class
    must_be_overridden
  end

  # null_object
  #
  # @return [Object]
  #
  def null_object
    must_be_overridden
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The controller associated with the decorator (Model#fields_table key).
  #
  # @return [Symbol]
  #
  def controller_config_key
    model_type
  end

  # The model associated with the decorator (Model#fields_table key).
  #
  # @return [Symbol]
  #
  def model_config_key
    model_type
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the controller/action configuration for the model.
  #
  # @param [Symbol, nil] type         Def: controller associated with decorator
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def controller_config(type = nil)
    type ||= controller_config_key
    ApplicationHelper::CONTROLLER_CONFIGURATION[type] || {}.freeze
  end

  # Get configured record fields relevant to the given context for the model.
  #
  # @param [Symbol] action            Def: `context[:action]`
  # @param [Symbol] type              Def: controller associated with decorator
  #
  # @return [ActionConfig, nil]       Frozen result.
  #
  def model_context_fields(action = nil, type = nil)
    type   ||= controller_config_key
    action ||= context[:action]
    Model.context_fields(type, action)
  end

  # Get configured record fields relevant to an :index action for the model.
  #
  # @param [Symbol, nil] type         Def: controller associated with decorator
  #
  # @return [ActionConfig]            Frozen result.
  #
  def model_index_fields(type = nil)
    type ||= controller_config_key
    Model.index_fields(type)
  end

  # Get configured record fields relevant to an :show action for the model.
  #
  # @param [Symbol, nil] type         Def: controller associated with decorator
  #
  # @return [ActionConfig]            Frozen result.
  #
  def model_show_fields(type = nil)
    type ||= controller_config_key
    Model.show_fields(type)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get all configured record fields for the model.
  #
  # @param [Symbol, nil] type         Def: controller associated with decorator
  #
  # @return [ActionConfig]            Frozen result.
  #
  def model_database_fields(type = nil)
    type ||= model_config_key
    Model.database_fields(type)
  end

  # Get all configured record fields for the model.
  #
  # @param [Symbol, nil] type         Def: controller associated with decorator
  #
  # @return [ActionConfig]            Frozen result.
  #
  def model_form_fields(type = nil)
    type ||= model_config_key
    Model.form_fields(type)
  end

  # Get all fields for a model instance table entry.
  #
  # @param [Symbol, nil] type         Def: controller associated with decorator
  #
  # @return [ActionConfig]
  #
  def model_table_fields(type = nil)
    model_show_fields(type)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration properties for a field.
  #
  # @param [Symbol, nil] field
  # @param [Hash]        opt          Passed to Field#for.
  #
  # @return [Field::Type, nil]
  #
  def field_for(field, **opt)
    opt[:prop] ||= field_configuration(field)
    Field.for(object, field, **opt)
  end

  # A working copy of the configuration properties for a field.
  #
  # @param [Symbol, String, nil] field
  # @param [Symbol, String, nil] action
  #
  # @return [FieldConfig]             Frozen if == FieldConfig::EMPTY.
  #
  def field_configuration(field, action = nil, **)
    Field.configuration_for(field, model_config_key, action)
  end

  # A working copy of the configuration properties for a field which has a
  # matching label.
  #
  # @param [String, Symbol, nil] label
  # @param [Symbol, String, nil] action
  #
  # @return [FieldConfig]             Frozen if == FieldConfig::EMPTY.
  #
  def field_configuration_for_label(label, action = nil, **)
    Field.configuration_for_label(label, model_config_key, action)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # config_lookup
  #
  # @param [String, Array] path       Partial I18n path.
  # @param [Hash]          opt        To ConfigurationHelper#config_lookup
  #
  # @return [any, nil]
  #
  def config_lookup(*path, **opt)
    opt[:ctrlr]  ||= opt.delete(:controller) || controller_config_key
    opt[:action] ||= :index
    h.config_lookup(*path, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
