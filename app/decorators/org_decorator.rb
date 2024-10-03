# app/decorators/org_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/org" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Org]
#
class OrgDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for Org

  # ===========================================================================
  # :section: Definitions shared with OrgsDecorator
  # ===========================================================================

  public

  module SharedPathMethods
    include BaseDecorator::SharedPathMethods
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module SharedGenericMethods

    include BaseDecorator::SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::Fields overrides
    # =========================================================================

    protected

    # Render a value for use on an input form.
    #
    # @param [String]   name
    # @param [any, nil] value
    # @param [Hash]     opt           Passed to super
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def render_form_field_item(name, value, **opt)
      opt[:type] = :text if opt[:'data-field'] == :ip_domain
      super
    end

    # =========================================================================
    # :section: BaseDecorator::Form overrides
    # =========================================================================

    public

    # Render a single label/value pair, forcing :ip_domain to be a single
    # input field.
    #
    # @param [String, Symbol] label
    # @param [any, nil]       value
    # @param [Hash]           opt     Passed to super
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    def render_form_pair(label, value, **opt)
      opt[:prop]   ||= field_configuration(opt[:field])
      opt[:field]  ||= opt.dig(:prop, :field)
      opt[:render] ||= :render_form_input if opt[:field] == :ip_domain
      super
    end

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    public

    # Generate a menu of org instances.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def items_menu(**opt)
      items_menu_role_constraints!(opt)
      opt[:sort] ||= { long_name: :asc }
      super
    end

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    protected

    # Generate a prompt for #items_menu.
    #
    # @return [String]
    #
    def items_menu_prompt(**)
      config_term(:org, :select)
    end

    # Descriptive term for an item of the given type.
    #
    # @param [Symbol, String, nil] model        Default: `#model_type`.
    # @param [Boolean]             capitalize
    #
    # @return [String]
    #
    def model_item_name(model: nil, capitalize: true)
      model ? super : config_term(:org, :model_name)
    end

  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module SharedInstanceMethods

    include BaseDecorator::SharedInstanceMethods
    include SharedPathMethods
    include SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::SharedInstanceMethods overrides
    # =========================================================================

    public

    # options
    #
    # @return [Org::Options]
    #
    def options
      context[:options] || Org::Options.new
    end

    # help_topic
    #
    # @param [Symbol, nil] sub_topic  Default: `context[:action]`.
    # @param [Symbol, nil] topic      Default: #model_type.
    #
    # @return [Array<Symbol>]
    #
    def help_topic(sub_topic = nil, topic = nil)
      topic ||= :organization
      super
    end

  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
  module SharedClassMethods
    include BaseDecorator::SharedClassMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Cause definitions to be included here and in the associated collection
  # decorator via BaseCollectionDecorator#collection_of.
  #
  module SharedDefinitions
    def self.included(base)
      base.include(SharedInstanceMethods)
      base.extend(SharedClassMethods)
    end
  end

end

class OrgDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section: BaseDecorator::Table overrides
  # ===========================================================================

  public

  # Fields and configurations augmented with a :value entry containing the
  # current field value.
  #
  # @param [Hash] opt                 Passed to super.
  #
  # @return [Hash{Symbol=>FieldConfig}]
  #
  def table_field_values(**opt)
    trace_attrs!(opt, __method__)
    t_opt    = trace_attrs_from(opt)
    controls = control_group { control_icon_buttons(**t_opt) }
    opt[:before] = { actions: controls }
    super
  end

  # ===========================================================================
  # :section: BaseDecorator::Form overrides
  # ===========================================================================

  public

  # Pass the value of the "welcome" URL parameter as a hidden field.
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def form_hidden(**opt)
    prm = url_parameters.slice(*AccountMailer::URL_PARAMETERS)
    if prm[:welcome].nil?
      super
    else
      super { |result, _| result.merge!(prm) }
    end
  end

  # Single-select menu - dropdown.
  #
  # @param [String]      name
  # @param [Array]       value
  # @param [Hash]        opt          Passed to super
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_menu_single(name, value, **opt)
    append_css!(opt, 'menu-control', 'advanced')
    super(name, value, **opt)
  end

end

__loading_end(__FILE__)
