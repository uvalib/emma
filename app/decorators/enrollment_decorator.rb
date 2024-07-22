# app/decorators/enrollment_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/enrollment" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Enrollment]
#
class EnrollmentDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for Enrollment

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

    extend Emma::Common::FormatMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @private
    # @type [String]
    ITEM_NAME = EnrollmentController.unit[:item]

    # =========================================================================
    # :section: BaseDecorator::Configuration overrides
    # =========================================================================

    public

    # Get all fields for a model instance table entry.
    #
    # @param [Symbol, nil] type       Passed to super.
    #
    # @return [ActionConfig]
    #
    def model_table_fields(type = nil)
      model_index_fields(type)
    end

    # Configuration properties for a field, with special handling for
    # :org_users.
    #
    # @param [Symbol, nil] field
    # @param [Hash]        opt          Passed to Field#for.
    #
    # @return [Field::Type, nil]
    #
    def field_for(field, **opt)
      super.tap do |result|
        if field == :org_users
          result.option[:row_count] = USER_SUBFIELDS_TYPES.size
        end
      end
    end

    # =========================================================================
    # :section: BaseDecorator::Controls overrides
    # =========================================================================

    public

    # Control icon definitions.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    # @see BaseDecorator::Controls#ICON_PROPERTIES
    #
    ICONS =
      BaseDecorator::Controls::ICONS.transform_values { |prop|
        tip = interpolate!(prop[:tooltip], item: ITEM_NAME)
        tip ? prop.merge(tooltip: tip) : prop
      }.deep_freeze

    # Icon definitions for this decorator.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def icon_definitions
      ICONS
    end

    # =========================================================================
    # :section: BaseDecorator::Field overrides
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
      opt[:prop]  ||= field_configuration(opt[:field])
      opt[:field] ||= opt.dig(:prop, :field)
      case opt[:field]
        when :ip_domain
          opt[:render] ||= :render_form_input
        when :org_users
          opt[:render] ||= :render_form_user
          opt.reverse_merge!(no_label: true)
      end
      super
    end

    # =========================================================================
    # :section: BaseDecorator::Form overrides
    # =========================================================================

    public

    # @private
    # @type [Hash{Symbol=>Symbol}]
    USER_SUBFIELDS_TYPES = {
      email:      :email,
      first_name: :text,
      last_name:  :text,
    }.freeze

    # render_form_user
    #
    # @param [String]   name
    # @param [any, nil] value
    # @param [Hash]     opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def render_form_user(name, value, **opt)
      trace_attrs!(opt)
      opt.delete(:'aria-labelledby')
      row   = opt.delete(:row) || 1
      base  = opt.delete(:base)
      l_css = DEF_LABEL_CLASS
      v_css = DEF_VALUE_CLASS

      cls   = css_class_array(opt[:class])
      stat  = cls.map(&:to_sym).intersection(status_markers.keys)
      opt[:class] = cls.reject { |c| (c == v_css) || c.start_with?('row-') }

      unless (v_id = opt.delete(:id))
        base = base&.delete_prefix('form-field-') || model_html_id(name)
        v_id = field_html_id(v_css, base: base, index: opt[:index])
      end
      v_opt = prepend_css(opt, v_css)

      l_id  = v_id.sub(/^#{v_css}/, l_css)
      l_opt = prepend_css(opt, l_css).merge!(status: stat)

      value = Enrollment.normalize_users(value).first || {}

      USER_SUBFIELDS_TYPES.map.with_index(row) { |(k, type), idx|
        row_cls      = "row-#{idx}"
        subfield     = k.to_s
        v_opt[:type] = type
        v_opt[:name] = "#{name}[#{subfield}]"
        v_opt[:id]                = l_opt[:for] = "#{v_id}-#{subfield}"
        v_opt[:'aria-labelledby'] = l_opt[:id]  = "#{l_id}-#{subfield}"
        v_opt[:'data-subfield']   = l_opt[:'data-subfield'] = subfield
        # noinspection RubyMismatchedArgumentType
        label = render_form_pair_label(k, **prepend_css(l_opt, row_cls))
        input = value[k]
        input = render_form_input(name, input, **prepend_css(v_opt, row_cls))
        label << input
      }.join.html_safe
    end

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    public

    # Generate a menu of enrollment instances.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def items_menu(**opt)
      items_menu_role_constraints!(opt)
      opt[:sort] ||= { id: :asc }
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
      config_term(:enrollment, :select)
    end

    # Descriptive term for an item of the given type.
    #
    # @param [Symbol, String, nil] model        Default: `#model_type`.
    # @param [Boolean]             capitalize
    #
    # @return [String]
    #
    def model_item_name(model: nil, capitalize: true)
      model ? super : config_term(:enrollment, :model_name)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # A button for finalizing an Enrollment by creating a new Org and User.
    #
    # @param [String, nil] label
    # @param [String]      css        Characteristic CSS class/selector.
    # @param [Hash]        opt        Passed to #button_to except for :id and
    #                                   AccountMailer::URL_PARAMETERS which go
    #                                   to #finalize_enrollment_path.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def finalize_button(label = nil, css: '.finalize-button', **opt)
      config   = config_page_section(:enrollment, :finalize)
      label  ||= config[:label]

      mail_opt = opt.extract!(*AccountMailer::URL_PARAMETERS)
      mail_opt = {} unless mail_opt.key?(:welcome)
      enroll   = opt.delete(:id) || object.id
      path     = h.finalize_enrollment_path(id: enroll, **mail_opt)

      opt[:title] ||= config[:tooltip]
      prepend_css!(opt, css)
      h.button_to(label, path, opt)
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
    # @return [Enrollment::Options]
    #
    def options
      context[:options] || Enrollment::Options.new
    end

    # help_topic
    #
    # @param [Symbol, nil] sub_topic  Default: `context[:action]`.
    # @param [Symbol, nil] topic      Default: #model_type.
    #
    # @return [Array<Symbol>]
    #
    def help_topic(sub_topic = nil, topic = nil)
      topic ||= :enrollment
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

class EnrollmentDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a single label/value pair in a list item with special handling for
  # the :org_users field.
  #
  # @param [String, Symbol, nil] label
  # @param [any, nil]            value
  # @param [Symbol]              field
  # @param [FieldConfig]         prop
  # @param [Hash]                opt    Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def list_render_pair(label, value, field:, prop:, **opt)
    value = table_org_users_value(value) if field == :org_users
    super
  end

  # Transform a field value for HTML rendering.
  #
  # @param [any, nil]    value
  # @param [Symbol, nil] field
  # @param [Hash]        opt          Passed to super.
  #
  # @return [any]                     HTML or scalar value.
  #
  def list_field_value(value, field:, **opt)
    super || EMPTY_VALUE
  end

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
    trace_attrs!(opt)
    t_opt    = trace_attrs_from(opt)
    controls = control_group { control_icon_buttons(**t_opt) }
    opt[:before] = { actions: controls }
    super
  end

  # Transform a field value for rendering in a table.
  #
  # @param [any, nil]    value
  # @param [Symbol, nil] field
  # @param [Hash]        opt          Passed to super.
  #
  # @return [any, nil]
  #
  def table_field_value(value, field:, **opt)
    return value if value.is_a?(ActiveSupport::SafeBuffer)
    return super unless value.present? && field.is_a?(Symbol)
    case field
      when :org_users then table_org_users_value(value)
      else                 value
    end || EMPTY_VALUE
  end

  # ===========================================================================
  # :section: BaseDecorator::Form overrides
  # ===========================================================================

  public

  # Generate a form with reCAPTCHA verification.
  #
  # @param [Hash] opt                 Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def model_form(**opt)
    opt.reverse_merge!(recaptcha: true) if recaptcha_active?
    super
  end

  # Pass the value of the "ticket" URL parameter as a hidden field.
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def form_hidden(**opt)
    prm = url_parameters.slice(*EnrollmentMailer::URL_PARAMETERS)
    if prm[:ticket].nil?
      super
    else
      super { |result, _| result.merge!(prm) }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Rendered table value for a :org_users field.
  #
  # @param [any, nil]      value
  # @param [Array<Symbol>] fields
  #
  # @return [String, nil]
  #
  def table_org_users_value(value, fields: %i[first_name last_name email])
    return if value.blank?
    Enrollment.normalize_users(value, log: false).map { |user|
      first, last, email = user.values_at(*fields).map!(&:presence)
      name  = [first, last].compact.presence&.join(' ')
      email = "(#{email})" if email && name
      [name, email].compact.join(' ')
    }.compact.join("\n")
  end

end

__loading_end(__FILE__)
