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
    not_implemented 'To be overridden'
  end

  # The ActiveRecord subclass associated with the decorator.
  #
  # @return [Class, nil]
  #
  # @see BaseDecorator#decorator_for
  #
  def ar_class
    not_implemented 'To be overridden'
  end

  # null_object
  #
  # @return [Object]
  #
  def null_object
    not_implemented 'To be overridden'
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
  # @param [Symbol] type              Def: controller associated with decorator
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def controller_config(type = nil)
    type ||= controller_config_key
    ApplicationHelper::CONTROLLER_CONFIGURATION[type] || {}.freeze
  end

  # Get configured record fields relevant to an :index action for the model.
  #
  # @param [Symbol] type              Def: controller associated with decorator
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def model_index_fields(type = nil)
    type ||= controller_config_key
    Model.index_fields(type)
  end

  # Get configured record fields relevant to an :show action for the model.
  #
  # @param [Symbol] type              Def: controller associated with decorator
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def model_show_fields(type = nil)
    type ||= controller_config_key
    Model.show_fields(type)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get configured record fields for the model.
  #
  # @param [Symbol] type              Def: model associated with decorator
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def model_config(type = nil)
    type ||= model_config_key
    Model.config_for(type)
  end

  # Get all configured record fields for the model.
  #
  # @param [Symbol] type              Def: model associated with decorator
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def model_database_fields(type = nil)
    type ||= model_config_key
    Model.database_fields(type)
  end

  # Get all configured record fields for the model.
  #
  # @param [Symbol] type              Def: model associated with decorator
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def model_form_fields(type = nil)
    type ||= model_config_key
    Model.form_fields(type)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration properties for a field.
  #
  # @param [Symbol] field
  # @param [Hash]   opt               Passed to Field#for.
  #
  # @return [Field::Type, nil]
  #
  def field_for(field, **opt)
    Field.for(object, field, model_config_key, **opt)
  end

  # Configuration properties for a field.
  #
  # @param [Symbol, String, nil] field
  # @param [Symbol, String, nil] action
  #
  # @return [Hash]                    Frozen result.
  #
  def field_configuration(field, action = nil, **)
    Field.configuration_for(field, model_config_key, action)
  end

  # Find the field whose configuration entry has a matching label.
  #
  # @param [String, Symbol, nil] label
  # @param [Symbol, String, nil] action
  #
  # @return [Hash]                    Frozen result.
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
  # @return [Any]
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