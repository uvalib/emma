# app/helpers/model_helper/form.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting creation of Model instances (both database
# items and API messages).
#
module ModelHelper::Form

  include ModelHelper::List

  include RoleHelper

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Indicate whether the given field value produces an <input> that should be
  # disabled.
  #
  # @param [Symbol, String]      field
  # @param [Symbol, String, nil] model  Default: `params[:controller]`
  #
  # @see UploadHelper#upload_readonly_form_field?
  #
  def readonly_form_field?(field, model = nil)
    model ||= params[:controller]
    Field.configuration_for(field, model)[:readonly].present?
  end

  # Indicate whether the given field value is required for validation.
  #
  # @param [Symbol, String]      field
  # @param [Symbol, String, nil] model  Default: `params[:controller]`
  #
  # @see UploadHelper#upload_required_form_field?
  #
  def required_form_field?(field, model = nil)
    model ||= params[:controller]
    Field.configuration_for(field, model)[:required].present?
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Render field/value pairs.
  #
  # @param [Model]               item
  # @param [String, Symbol, nil] model        Default: `params[:controller]`.
  # @param [String, Symbol, nil] action       Default: `params[:action]`.
  # @param [Hash, nil]           pairs        Except #render_form_pair options.
  # @param [Integer, nil]        row_offset   Def: 0.
  # @param [String, nil]         separator    Def: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Hash]                opt
  # @param [Proc]                block        Passed to #field_values.
  #
  # @option opt [Integer] :index              Offset to make unique element IDs
  #                                             passed to #render_form_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # Compare with:
  # #render_field_values
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def render_form_fields(
    item,
    model:      nil,
    action:     nil,
    pairs:      nil,
    row_offset: nil,
    separator:  DEFAULT_ELEMENT_SEPARATOR,
    **opt,
    &block
  )
    return ''.html_safe unless item
    pairs  = field_values(item, pairs, &block)
    model  = (model  || params[:controller])&.to_sym
    action = (action || params[:action])&.to_sym

    opt[:row]   = row_offset || 0
    opt[:model] = model

    # noinspection RubyNilAnalysis
    pairs.map { |label, value|
      field = lbl = val = nil
      if value.is_a?(Symbol)
        field = value
      elsif (label == :file_data) || (label == :emma_data)
        next
      elsif label.is_a?(Symbol) && value.is_a?(Hash)
        field = label
        lbl   = value[:label]
        val   = field
      elsif label.is_a?(Symbol)
        field = label
        lbl   = Field.configuration_for(field, model, action)[:label]
      elsif model
        field = Field.configuration_for_label(label, model, action)[:field]
      end
      # @type [String] label
      label       = lbl || label || labelize(field)
      value       = val || value
      opt[:row]     += 1
      opt[:field]    = field
      opt[:disabled] = readonly_form_field?(field, model) if field
      opt[:required] = required_form_field?(field, model) if field
      value = render_value(item, value, model: model, index: opt[:index])
      render_form_pair(label, value, **opt)
    }.compact.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair.
  #
  # @param [String, Symbol] label
  # @param [Any]            value
  # @param [Symbol]         field       For 'data-field' attribute.
  # @param [Symbol, String] model       Default: `params[:controller]`
  # @param [Integer]        index       Offset for making unique element IDs.
  # @param [Integer]        row         Display row.
  # @param [Boolean]        disabled
  # @param [Boolean]        required    For 'data-required' attribute.
  # @param [Hash]           opt
  #
  # @return [ActiveSupport::SafeBuffer] HTML label and value elements.
  # @return [nil]                       If *value* is blank.
  #
  # Compare with:
  # #render_pair
  #
  def render_form_pair(
    label,
    value,
    field:    nil,
    model:    nil,
    index:    nil,
    row:      1,
    disabled: nil,
    required: nil,
    **opt
  )
    model ||= params[:controller]
    prop    = Field.configuration_for(field, model)
    return if prop[:ignored]
    return if prop[:role] && !has_role?(prop[:role])

    # Pre-process label to derive names and identifiers.
    base = model_html_id(field || label)
    name = field&.to_s || base
    type = "field-#{base}"
    v_id = type.dup
    l_id = +"label-#{base}"
    [v_id, l_id].each { |id| id << "-#{index}" } if index

    # Pre-process value.
    render_method = placeholder = range = nil
    if value == EMPTY_VALUE
      placeholder = value
      value = nil
    elsif value.is_a?(Field::Type)
      range = value.base if valid_range?(value.base)
      multi = (value.mode == :multiple)
      value = value.value
      render_method =
        if range
          multi ? :render_form_menu_multi  : :render_form_menu_single
        else
          multi ? :render_form_input_multi : :render_form_input
        end
    end
    render_method ||= :render_form_input
    placeholder   ||= prop[:placeholder]
    value    = Array.wrap(value).compact_blank
    disabled = prop[:readonly] if disabled.nil?
    required = prop[:required] if required.nil?
    fieldset = false # (render_method == :render_form_menu_multi)

    # Create a help icon control if applicable.  (The associated popup panel
    # require some special handling to get it to appear above other elements
    # that are in different stacking contexts.)
    help = prop[:help].presence
    help &&= help_popup(*help, panel: { class: 'z-order-capture' })

    # Create status marker icon.
    status = []
    status << :required if required
    status << :disabled if disabled
    status << :invalid  if required && value.empty?
    status << :valid    if value.present?
    marker = status_marker(status: status, label: label)

    # Option settings for both label and value.
    prepend_classes!(opt, "row-#{row}", type, *status)

    # Label for input element.
    l_opt = append_classes(opt, 'label')
    l_opt[:id]      = l_id
    l_opt[:for]     = v_id
    l_opt[:title] ||= prop[:tooltip] if prop[:tooltip]
    label  = prop[:label] || label
    wrap   = !label.is_a?(ActiveSupport::SafeBuffer)
    label  = label ? ERB::Util.h(label) : labelize(name)
    legend = (label.dup if fieldset)
    label  = html_span(label, class: 'text') if wrap
    label  = html_span { label << help }     if help
    label << marker
    label  = fieldset ? html_div(label, l_opt) : label_tag(name, label, l_opt)

    # Input element pre-populated with value.
    v_opt = append_classes(opt, 'value')
    v_opt[:id]                = v_id
    v_opt[:name]              = name
    v_opt[:title]             = 'System-generated; not modifiable.' if disabled # TODO: I18n
    v_opt[:readonly]          = true        if disabled # Not :disabled.
    v_opt[:placeholder]       = placeholder if placeholder
    v_opt[:'data-field']      = field       if field
    v_opt[:'data-required']   = true        if required
    v_opt[:'aria-labelledby'] = l_id
    v_opt[:base]              = base
    v_opt[:range]             = range       if range
    v_opt[:legend]            = legend      if legend
    value = send(render_method, name, value, **v_opt)

    # noinspection RubyMismatchedReturnType
    label << value
  end

  # Single-select menu - drop-down.
  #
  # @param [String] name
  # @param [Array]  value             Selected value(s) from `range#values`.
  # @param [Class]  range             A class derived from EnumType whose
  #                                     #values method will be used to populate
  #                                     the menu.
  # @param [Hash]   opt               Passed to #select_tag except for:
  #
  # @option opt [String] :name        Overrides *name*
  # @option opt [String] :base        Name and id for <select>; default: *name*
  #
  # @raise [RuntimeError]             If *range* is not an EnumType.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/entry-form.js *updateMenu()*
  #
  def render_form_menu_single(name, value, range:, **opt)
    css_selector = '.menu.single'
    valid_range?(range, exception: true)
    normalize_attributes!(opt)
    opt, html_opt = partition_hash(opt, :readonly, :base, :name)
    field = html_opt[:'data-field']
    name  = opt[:name] || name || opt[:base] || field
    prepend_classes!(html_opt, css_selector)

    selected = Array.wrap(value).compact.presence || ['']

    menu =
      range.pairs.map do |item_value, item_label|
        item_value = item_value.to_s
        item_label ||= item_value.titleize
        [item_label, item_value]
      end
    menu.unshift(['(unset)', '']) # TODO: I18n
    menu = options_for_select(menu, selected)
    html_opt[:disabled] = true if opt[:readonly]
    select_tag(name, menu, html_opt)
  end

  # Multi-select menu - scrollable list of checkboxes.
  #
  # @param [String] name
  # @param [Array]  value             Selected value(s) from `range#values`.
  # @param [Class]  range             A class derived from EnumType whose
  #                                     #values method will be used to populate
  #                                     the menu.
  # @param [Hash]   opt               Passed to #field_set_tag except for:
  #
  # @option opt [String] :name        Overrides *name*
  # @option opt [String] :base        Name and id for <select>; default: *name*
  #
  # @raise [RuntimeError]             If *range* is not an EnumType.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/entry-form.js *updateFieldsetCheckboxes()*
  #
  def render_form_menu_multi(name, value, range:, **opt)
    css_selector = '.menu.multi'
    valid_range?(range, exception: true)
    normalize_attributes!(opt)
    opt, html_opt = partition_hash(opt, :id, :readonly, :base, :name)
    field = html_opt[:'data-field']
    name  = opt[:name] || name || opt[:base] || field
    prepend_classes!(html_opt, css_selector)

    # Checkbox elements.
    selected = Array.wrap(value).compact.presence
    cb_opt   = { role: 'option' }
    checkboxes =
      range.pairs.map do |item_value, item_label|
        cb_name          = "[#{field}][]"
        cb_value         = item_value
        cb_opt[:id]      = "#{field}_#{item_value}"
        cb_opt[:label]   = item_label
        cb_opt[:checked] = selected&.include?(item_value)
        render_check_box(cb_name, cb_value, **cb_opt)
      end

    # Grouped checkboxes (Chrome problem with styling <fieldset>).
    gr_opt = html_opt.except(:'data-field', :'data-required')
    gr_opt.merge!(role: 'listbox', multiple: true, name: name)
    gr_opt[:tabindex] = -1
    group = html_div(*checkboxes, gr_opt)

    field_opt = html_opt.merge(id: opt[:id], name: name)
    field_opt[:disabled] = true if opt[:readonly]
    html_div(field_opt) { group }
  end

  # Multiple single-line inputs.
  #
  # @param [String] name
  # @param [Array]  value
  # @param [Hash]   opt               Passed to :field_set_tag except for:
  #
  # @option [Boolean] :disabled       Passed to :render_form_input
  # @option [Integer] :count
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/entry-form.js *updateFieldsetInputs()*
  #
  def render_form_input_multi(name, value, **opt)
    css_selector = '.input.multi'
    render_field_item(name, value, **prepend_classes!(opt, css_selector))
  end

  # render_form_input
  #
  # @param [String] name
  # @param [Any]    value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/entry-form.js *updateTextInputField()*
  #
  def render_form_input(name, value, **opt)
    css_selector = '.input.single'
    render_field_item(name, value, **prepend_classes!(opt, css_selector))
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Form submit button.
  #
  # @param [Hash]                config   Button info for model actions.
  # @param [String, Symbol, nil] action   Default: `params[:action]`.
  # @param [String, nil]         label    Override button label.
  # @param [Hash] opt                     Passed to #submit_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_submit_button(config:, action: nil, label: nil, **opt)
    css_selector = '.submit-button'
    action ||= params[:action]
    config   = config.dig(action&.to_sym, :submit) || {}
    label  ||= config[:label]

    prepend_classes!(opt, css_selector)
    opt[:title] ||= config.dig(:disabled, :tooltip)
    submit_tag(label, opt)
  end

  # Form cancel button.
  #
  # @param [Hash]                config   Button info for model actions.
  # @param [String, Symbol, nil] action   Default: `params[:action]`.
  # @param [String, nil]         label    Override button label.
  # @param [String, Hash, nil]   url      Default: `history.back()`.
  # @param [Hash] opt                     Passed to #button_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_cancel_button(config:, action: nil, label: nil, url: nil, **opt)
    css_selector = '.cancel-button'
    action ||= params[:action]
    config   = config.dig(action&.to_sym, :cancel) || {}
    label  ||= config[:label]

    prepend_classes!(opt, css_selector)
    opt[:title] ||= config[:tooltip]
    opt[:type]  ||= 'reset'

    if opt[:'data-path'].present?
      button_tag(label, opt)
    else
      url ||= (request.referer if local_request? && !same_request?)
      url ||= 'javascript:history.back();'
      # noinspection RubyMismatchedArgumentType
      make_link(label, url, **opt)
    end
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # Field type indicators mapped on to related class(es).
  #
  # @type [Hash{Symbol=>Array<Class>}]
  #
  RENDER_FIELD_TYPE_TABLE = {
    check:  [Boolean, TrueClass, FalseClass],
    date:   [IsoDate, IsoDay, Date, DateTime],
    number: [Integer, BigDecimal],
    time:   [Time, ActiveSupport::TimeWithZone],
    year:   [IsoYear],
  }.transform_values! { |types|
    types.flat_map { |type|
      # noinspection RubyMismatchedArgumentType
      [type].tap do |related|
        name = (type == BigDecimal) ? 'Decimal' : type
        related << safe_const_get("Axiom::Types::#{name}")
        related << safe_const_get("ActiveModel::Type::#{name}")
      end
    }.compact
  }.deep_freeze

  # Mapping of actual type to the appropriate field type indicator.
  #
  # @type [Hash{Class=>Symbol}]
  #
  RENDER_FIELD_TYPE =
    RENDER_FIELD_TYPE_TABLE.flat_map { |field, types|
      types.map { |type| [type, field] }
    }.sort_by { |pair| pair.first.to_s }.to_h.freeze

  # Convert certain field types.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  REPLACE_FIELD_TYPE = {
=begin
    year: :text, # Currently treating :year as plain text.
    date: :text, # Currently treating :date as plain text.
    time: :text, # Currently treating :time as plain text.
=end
  }.freeze

  # render_field_item
  #
  # @param [String] name
  # @param [Any]    value
  # @param [Hash]   opt               Passed to render method except for:
  #
  # @option opt [String]         :base
  # @option opt [String]         :name
  # @option opt [Symbol, String] :model   Default: `params[:controller]`
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_field_item(name, value, **opt)
    normalize_attributes!(opt)
    opt, html_opt = partition_hash(opt, :base, :name, :model)
    field = html_opt[:'data-field']
    name  = opt[:name] || name || opt[:base] || field
    value = Array.wrap(value).compact_blank
    model = opt[:model] || params[:controller]
    type  = Field.configuration_for(field, model)[:type]
    type  = type.to_sym                          if type.is_a?(String)
    type  = RENDER_FIELD_TYPE[value.first.class] unless type.is_a?(Symbol)
    type  = REPLACE_FIELD_TYPE[type] || type || :text
    value =
      case type
        when :check    then true?(value.first)
        when :number   then value.first.to_s.remove(/[^\d]/)
        when :year     then value.first.to_s.sub(/\s.*$/, '')
        when :date     then value.first.to_s
        when :time     then value.first.to_s.sub(/^([^ ]+).*$/, '\1')
        when :textarea then value.join("\n").split(/[ \t]*\n[ \t]*/).join("\n")
        else value.map { |v| v.to_s.strip.presence }.compact.join(' | ')
      end
    case type
      when :check    then render_check_box(name, value, **html_opt)
      when :number   then number_field_tag(name, value, html_opt.merge(min: 0))
      when :year     then text_field_tag(name, value, html_opt)
      when :date     then date_field_tag(name, value, html_opt)
      when :time     then time_field_tag(name, value, html_opt)
      when :textarea then text_area_tag(name, value, html_opt)
      else                text_field_tag(name, value, html_opt)
    end
  end

  # Local options for #render_check_box.
  #
  # @type [Array<Symbol>]
  #
  CHECK_OPTIONS =
    %i[id checked disabled readonly required data-required label].freeze

  # render_check_box
  #
  # @param [String] name
  # @param [Any]    value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_check_box(name, value, **opt)
    css_selector  = '.checkbox.single'
    opt, html_opt = partition_hash(opt, *CHECK_OPTIONS)
    normalize_attributes!(opt)

    # Checkbox control.
    checked  = opt.delete(:checked)
    checkbox = check_box_tag(name, value, checked, opt)

    # Label for checkbox.
    lbl_opt  = { for: opt[:id] }.compact
    label    = opt.delete(:label) || value
    label    = label_tag(name, label, lbl_opt)

    # Checkbox/label combination.
    html_div(prepend_classes!(html_opt, css_selector)) do
      checkbox << label
    end
  end

  # STATUS_MARKER
  #
  # @type [Hash{Symbol=>Hash{Symbol=>String}}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  STATUS_MARKER = I18n.t('emma.upload.status_marker', default: {}).deep_freeze

  # Generate a marker which can indicate the status of an input field.
  #
  # @param [Symbol, Array<Symbol>] status   One or more of %[invalid required].
  # @param [String, Symbol]        label    Used with :required.
  # @param [Hash]                  opt      Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def status_marker(status: nil, label: nil, **opt)
    css_selector  = '.status-marker'
    status = Array.wrap(status).compact
    entry  = STATUS_MARKER.values_at(*status).first
    icon, tip = entry&.values_at(:label, :tooltip)
    opt[:'data-icon'] = icon if icon
    if tip
      if tip.include?('%')
        label &&= label.to_s.sub(/[[:punct:]]+$/, '')
        tip %= { This: (label ? %Q("#{label}") : 'This') } # TODO: I18n
      end
      opt[:'data-title'] = tip
      opt[:title] ||= tip
    else
      opt[:'aria-hidden'] = true
    end
    html_span(icon, prepend_classes!(opt, css_selector, *status))
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # Indicate whether the value is a valid range type.
  #
  # @param [Any]     range
  # @param [Boolean] exception        If *true*, raise an exception if *false*.
  #
  # @raise [RuntimeError]             If not valid and *exception* is *true*.
  #
  def valid_range?(range, exception: false)
    valid = range.is_a?(Class) && (range < EnumType)
    exception &&= !valid
    raise "range: #{range.inspect}: not a subclass of EnumType" if exception
    valid
  end

  # Translate attributes.
  #
  # @param [Hash] opt
  #
  # @return [Hash]                    The potentially-modified *opt* hash.
  #
  # == Implementation Notes
  # Disabled input fields are given the :readonly attribute because the
  # :disabled attribute prevents those fields from being included in the data
  # sent with the form submission.
  #
  def normalize_attributes!(opt)
    field    = opt.delete(:field)    || opt[:'data-field']
    required = opt.delete(:required) || opt[:'data-required']
    readonly = opt.delete(:disabled) || opt[:readonly]

    opt[:'data-field']    = field    if field
    opt[:'data-required'] = true     if required
    opt[:readonly]        = true     if readonly

    append_classes!(opt, 'required') if required
    append_classes!(opt, 'disabled') if readonly
    opt
  end

  # ===========================================================================
  # :section: Item forms (delete pages)
  # ===========================================================================

  public

  # Submit button for the delete model form.
  #
  # @param [Hash]                config   Button info for model actions.
  # @param [String, Symbol, nil] action   Default: `params[:action]`.
  # @param [String, nil]         label    Override button label.
  # @param [String, Hash, nil]   url
  # @param [Hash]                opt      Passed to #button_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def delete_submit_button(config:, action: nil, label: nil, url: nil, **opt)
    css_selector = '.submit-button'
    action ||= params[:action] || :delete
    config   = config.dig(action&.to_sym, :submit) || {}
    label  ||= config[:label]
    opt[:title]  ||= config.dig(:disabled, :tooltip)
    opt[:role]   ||= 'button'
    opt[:method] ||= :delete
    prepend_classes!(opt, css_selector)
    append_classes!(opt, (url ? 'best-choice' : 'forbidden'))
    button_to(label, url, opt)
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
