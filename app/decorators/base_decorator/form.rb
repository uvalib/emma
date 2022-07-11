# app/decorators/base_decorator/form.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting the creation and modification of Model instances.
#
module BaseDecorator::Form

  include BaseDecorator::List

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration-related values which are available to either the class or the
  # instance.
  #
  module Values

    # Model-specific field group configuration.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def field_groups
      @field_groups ||= config_lookup('field_group')
    end

    # Model-specific status marker configuration.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def status_markers
      @status_markers ||= config_lookup('status_marker')
    end

    # Form action button configuration.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    def form_actions
      @form_actions ||= generate_form_actions
    end

    # Form action button configuration.
    #
    # @param [Array<Symbol>] actions
    #
    # @type [Hash{Symbol=>Hash}]
    #
    def generate_form_actions(actions = %i[new edit delete])
      actions.map { |action| [action, config_button_values(action)] }.to_h
    end

  end

  include Values

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Render field/value pairs.
  #
  # @param [String, Symbol, nil] action
  # @param [Hash, nil]           pairs        Except #render_form_pair options.
  # @param [Integer, nil]        row_offset   Def: 0.
  # @param [String, nil]         separator    Def: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Hash]                opt
  #
  # @option opt [Integer] :index              Offset to make unique element IDs
  #                                             passed to #render_form_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Implementation Notes
  # Compare with BaseDecorator::List#render_field_values
  #
  # Special handling for :effective_id based on the Hash value set up in
  # AccountDecorator#form_fields.
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def render_form_fields(
    action:     nil,
    pairs:      nil,
    row_offset: nil,
    separator:  DEFAULT_ELEMENT_SEPARATOR,
    **opt
  )
    return ''.html_safe unless pairs || object
    action  ||= context[:action]
    opt[:row] = row_offset || 0
    field_values(pairs).map { |label, value|
      next if (label == :file_data) || (label == :emma_data)
      if value.is_a?(Symbol)
        field  = value
        config = field_configuration(field, action)
      elsif label.is_a?(Symbol) && value.is_a?(Hash)
        field  = label
        label  = value[:label]
        config = field_configuration(field, action)
        value  = field_for(field, config: config)
      elsif label.is_a?(Symbol)
        field  = label
        config = field_configuration(field, action)
        label  = config[:label] || label
      else
        config = field_configuration_for_label(label, action)
        field  = config[:field]
      end

      opt[:row]     += 1
      opt[:field]    = field
      opt[:disabled] = config[:readonly].present?
      opt[:required] = config[:required].present?

      value = render_value(value, field: field, index: opt[:index])
      render_form_pair(label, value, **opt)
    }.compact.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair.
  #
  # @param [String, Symbol] label
  # @param [Any]            value
  # @param [Symbol]         field       For 'data-field' attribute.
  # @param [Integer]        index       Offset for making unique element IDs.
  # @param [Integer]        row         Display row.
  # @param [Boolean]        disabled
  # @param [Boolean]        required    For 'data-required' attribute.
  # @param [Hash]           opt
  #
  # @return [ActiveSupport::SafeBuffer] HTML label and value elements.
  # @return [nil]                       If *value* is blank.
  #
  # == Implementation Notes
  # Compare with BaseDecorator::List#render_pair
  #
  def render_form_pair(
    label,
    value,
    field:    nil,
    index:    nil,
    row:      1,
    disabled: nil,
    required: nil,
    **opt
  )
    prop = field_configuration(field)
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
    render_method = placeholder = range = optional = nil
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
    elsif value.is_a?(Hash)
      prop  = prop.except(:origin, :readonly).merge!(min: 0, max: 1)
      range = value[:range] || prop[:range]
      value = value[:value]
      required = disabled = false
      render_method = :render_form_menu_single
    end

    case field
      when :password, :current_password, :password_confirmation
        prop     = prop.except(:origin, :readonly).merge!(min: 0, max: 1)
        required = disabled = false
        optional = true
        value    = nil
        render_method   = :render_form_password
      else
        render_method ||= :render_form_input
    end
    placeholder ||= prop[:placeholder]

    value    = Array.wrap(value).compact_blank
    disabled = prop[:readonly] if disabled.nil?
    required = prop[:required] if required.nil?
    fieldset = false # (render_method == :render_form_menu_multi)

    # Create a help icon control if applicable.  (The associated popup panel
    # require some special handling to get it to appear above other elements
    # that are in different stacking contexts.)
    help = prop[:help].presence
    help &&= h.help_popup(*help, panel: { class: 'z-order-capture' })

    # Create status marker icon.
    status = []
    status << :required if required
    status << :disabled if disabled
    status << :invalid  if required && value.empty?
    status << :valid    if value.present?
    marker = status_marker(status: status, label: label)

    # Option settings for both label and value.
    prepend_css!(opt, "row-#{row}", type, *status)

    # Label for input element.
    l_opt = append_css(opt, 'label')
    l_opt[:id]      = l_id
    l_opt[:for]     = v_id
    l_opt[:title] ||= prop[:tooltip] if prop[:tooltip]
    label  = prop[:label] || label
    label  = labelize(name) unless label.is_a?(String)
    wrap   = !label.is_a?(ActiveSupport::SafeBuffer)
    legend = (label.dup if fieldset)
    label  = wrap ? html_span(label, class: 'text') : ERB::Util.h(label)
    label  = html_span { label << help } if help
    label << marker                      if marker
    label = fieldset ? html_div(label, l_opt) : h.label_tag(name, label, l_opt)

    # Input element pre-populated with value.
    v_opt = append_css(opt, 'value')
    v_opt[:id]                = v_id
    v_opt[:name]              = name
    v_opt[:title]             = 'System-generated; not modifiable.' if disabled # TODO: I18n
    v_opt[:readonly]          = true        if disabled # Not :disabled.
    v_opt[:placeholder]       = placeholder if placeholder
    v_opt[:'data-field']      = field       if field
    v_opt[:'data-required']   = false       if optional
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
  # @param [String]      name
  # @param [Array]       value        Selected value(s) from `range#values`.
  # @param [Class|Array] range        A class derived from EnumType whose
  #                                     #values method will be used to populate
  #                                     the menu.
  # @param [Hash]        opt          Passed to #select_tag except for:
  #
  # @option opt [String] :name        Overrides *name*
  # @option opt [String] :base        Name and id for *select*; default: *name*
  #
  # @raise [RuntimeError]             If *range* is not an EnumType.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/model-form.js *updateMenu()*
  #
  def render_form_menu_single(name, value, range:, **opt)
    css = '.menu.single'
    range.is_a?(Array) or valid_range?(range, exception: true)
    normalize_attributes!(opt)
    html_opt = remainder_hash!(opt, :readonly, :base, :name)
    field    = html_opt[:'data-field']
    name     = opt[:name] || name || opt[:base] || field
    prepend_css!(html_opt, css)

    selected = Array.wrap(value).compact.presence || ['']

    # noinspection RailsParamDefResolve
    pairs = (range.try(:pairs) || Array.wrap(range)).dup
    menu  =
      pairs.map do |item_value, item_label|
        item_value = item_value.to_s
        item_label ||= item_value.titleize
        [item_label, item_value]
      end
    menu.unshift(['(unset)', '']) unless menu.first.last.blank? # TODO: I18n
    menu = h.options_for_select(menu, selected)
    html_opt[:disabled] = true if opt[:readonly]
    h.select_tag(name, menu, html_opt)
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
  # @option opt [String] :base        Name and id for *select*; default: *name*
  #
  # @raise [RuntimeError]             If *range* is not an EnumType.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/feature/model-form.js *updateFieldsetCheckboxes()*
  #
  def render_form_menu_multi(name, value, range:, **opt)
    css = '.menu.multi'
    valid_range?(range, exception: true)
    normalize_attributes!(opt)
    html_opt = remainder_hash!(opt, :id, :readonly, :base, :name)
    field    = html_opt[:'data-field']
    name     = opt[:name] || name || opt[:base] || field
    prepend_css!(html_opt, css)

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
  # @see file:javascripts/feature/model-form.js *updateFieldsetInputs()*
  #
  def render_form_input_multi(name, value, **opt)
    css = '.input.multi'
    prepend_css!(opt, css)
    render_field_item(name, value, **opt)
  end

  # render_form_input
  #
  # @param [String] name
  # @param [Any]    value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/feature/model-form.js *updateTextInputField()*
  #
  def render_form_input(name, value, **opt)
    css = '.input.single'
    prepend_css!(opt, css)
    render_field_item(name, value, **opt)
  end

  # render_form_email
  #
  # @param [String] name
  # @param [Any]    value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_email(name, value, **opt)
    render_form_input(name, value, **opt, type: :email)
  end

  # render_form_password
  #
  # @param [String] name
  # @param [Any]    value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_password(name, value, **opt)
    render_form_input(name, value, **opt, type: :password)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # Generates a line in the form associated with *opt[:'data-field']*.
  #
  # @param [String, nil] note
  # @param [String, nil] label        Blank by default.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def form_note_pair(note, label: nil, **opt)
    return if note.blank?
    label = form_input_fill(label, **opt) unless label&.html_safe?
    note  = form_input_note(note,  **opt) unless note.html_safe?
    # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
    label << note
  end

  # The leading column associated with a text note immediately below a form
  # input element (in the trailing column).
  #
  # @param [String, nil] filler
  # @param [Hash]        opt          Passed through #form_input_related_opt.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_input_fill(filler = nil, **opt)
    opt = form_input_related_opt('label', **opt)
    html_span(filler, opt)
  end

  # A text note immediately below a form input element.
  #
  # @param [String, nil] note
  # @param [Hash]        opt          Passed through #form_input_related_opt.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_input_note(note, **opt)
    opt = form_input_related_opt('note', **opt)
    opt[:separator] = ''
    html_tag(:em, opt) { "(#{note})" }
  end

  # Options assumed to be related to a field element which are not retained by
  # elements related to it (for the purpose of field grouping).
  #
  # @type [Array<Symbol>]
  #
  RELATED_IGNORED_KEYS = %i[
    id
    name
    readonly
    placeholder
    data-field
    data-required
    aria-labelledby
    base
    range
    legend
    type
    minlength
    maxlength
  ].freeze

  # Modify the provided options for a field related to an form input field.
  # Options that are assumed to be related to the actual field element are
  # removed.
  #
  # @param [String, nil] css
  # @param [Hash]        opt
  #
  # @return [Hash]
  #
  # @see file:javascripts/feature/model-form.js *updateFieldAndLabel()*
  #
  def form_input_related_opt(css = nil, **opt)
    opt[:'data-for'] = opt.values_at(:'data-field', :'data-for').first
    opt.except!(*RELATED_IGNORED_KEYS)
    prepend_css!(opt, css) if css
    remove_css!(opt, 'value')
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # @private
  DEFAULT_FORM_ACTION = :new

  # Generate a form with controls for entering field values and submitting.
  #
  # @param [String]         label     Label for the submit button.
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [String]         cancel    URL for cancel button action (def: :back)
  # @param [Boolean]        uploader  If *true*, active client-side logic for
  #                                     supporting file upload.
  # @param [Hash]           outer     Passed to outer div.
  # @param [Hash]           opt       Passed to #form_with except for:
  #
  # @option opt [String]  :cancel     URL for cancel button action (default:
  #                                     :back).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/model-form.js *isFileUploader()*
  #
  def model_form(
    label:    nil,
    action:   nil,
    cancel:   nil,
    uploader: nil,
    outer:    nil,
    **opt
  )
    css       = '.model-form'
    outer_css = '.form-container'
    uploader  = uploader.is_a?(TrueClass) ? 'file-uploader' : uploader.presence
    action    = action&.to_sym || context[:action] || DEFAULT_FORM_ACTION

    case action
      when :edit
        opt[:method] ||= :put
        opt[:url]      = update_path
      when :new
        opt[:method] ||= :post
        opt[:url]      = create_path
      else
        Log.warn("#{self.class}.#{__method__}: #{action}: unexpected action")
    end
    opt[:multipart]    = true
    opt[:autocomplete] = 'off'

    classes = [action, model_type, uploader]
    prepend_css!(opt, css, *classes)
    scroll_to_top_target!(opt)

    buttons   = form_buttons(label: label, action: action, cancel: cancel)
    outer_opt = prepend_css(outer, outer_css, *classes)
    html_div(outer_opt) do
      # @type [ActionView::Helpers::FormBuilder] f
      h.form_with(model: object, **opt) do |f|
        sections  = form_hidden_fields(f)
        sections << form_top_controls(f, *buttons)
        sections << field_container
        sections << form_bottom_controls(f, *buttons)
        safe_join(sections.compact, "\n")
      end
    end
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # @private
  FORM_BUTTON_OPTIONS = %i[action cancel label]

  # Control elements always visible at the top of the input form.
  #
  # @param [ActionView::Helpers::FormBuilder, nil] f
  # @param [Array<ActiveSupport::SafeBuffer>]      buttons
  # @param [Hash]                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [parts] Extend or replace control elements.
  # @yieldparam [Array<ActiveSupport::SafeBuffer>] parts
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>]
  #
  def form_top_controls(f = nil, *buttons, **opt)
    css   = '.controls.top'
    parts = [form_top_button_tray(f, *buttons), field_group_controls]
    parts = yield(parts) if block_given?
    html_div(*parts, prepend_css!(opt, css))
  end

  # form_top_button_tray
  #
  # @param [ActionView::Helpers::FormBuilder, nil] f
  # @param [Array<ActiveSupport::SafeBuffer>]      buttons
  # @param [Hash]                                  opt
  # @param [Proc]                                  block
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #form_button_tray
  #
  def form_top_button_tray(f = nil, *buttons, **opt, &block)
    form_button_tray(f, *buttons, **opt, &block)
  end

  # Convenience submit and cancel buttons below the fields.
  #
  # @param [ActionView::Helpers::FormBuilder, nil] f
  # @param [Array<ActiveSupport::SafeBuffer>]      buttons
  # @param [Hash]                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [parts] Extend or replace control elements.
  # @yieldparam [Array<ActiveSupport::SafeBuffer>] parts
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>]
  #
  def form_bottom_controls(f = nil, *buttons, **opt)
    css   = '.controls.bottom'
    parts = [form_bottom_button_tray(f, *buttons)]
    parts = yield(parts) if block_given?
    html_div(*parts, prepend_css!(opt, css))
  end

  # form_bottom_button_tray
  #
  # @param [ActionView::Helpers::FormBuilder, nil] f
  # @param [Array<ActiveSupport::SafeBuffer>]      buttons
  # @param [Hash]                                  opt
  # @param [Proc]                                  block
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #form_button_tray
  #
  def form_bottom_button_tray(f = nil, *buttons, **opt, &block)
    form_button_tray(f, *buttons, **opt, &block)
  end

  # form_button_tray
  #
  # @param [ActionView::Helpers::FormBuilder, nil] f
  # @param [Array<ActiveSupport::SafeBuffer>]      buttons
  # @param [Hash]                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [parts] Extend or replace button tray elements.
  # @yieldparam [Array<ActiveSupport::SafeBuffer>] parts
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>]
  #
  def form_button_tray(f = nil, *buttons, **opt)
    css    = '.button-tray'
    fb_opt = extract_hash!(opt, *FORM_BUTTON_OPTIONS)
    # noinspection RubyMismatchedArgumentType
    buttons.unshift(f) if f && !f.is_a?(ActionView::Helpers::FormBuilder)
    buttons = form_buttons(**fb_opt) if buttons.blank?
    buttons = yield(buttons)         if block_given?
    html_div(*buttons, prepend_css!(opt, css))
  end

  # Basic form controls.
  #
  # @param [String] label             Label for the submit button.
  # @param [String] cancel            URL for cancel button action (def: :back)
  # @param [Hash]   opt               Passed to button methods
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  # @yield [parts] Extend or replace results.
  # @yieldparam [Array<ActiveSupport::SafeBuffer>] parts
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>]
  #
  def form_buttons(label: nil, cancel: nil, **opt)
    opt[:action] ||= context[:action] || DEFAULT_FORM_ACTION
    buttons = []
    buttons << submit_button(label: label,  **opt)
    buttons << cancel_button(url:   cancel, **opt)
    block_given? ? yield(buttons) : buttons
  end

  # Form submit button.
  #
  # @param [String, Symbol, nil] action
  # @param [String, nil]         label    Override button label.
  # @param [Hash] opt                     Passed to #submit_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/model-form.js *submitButton()*
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def submit_button(action: nil, label: nil, **opt)
    css     = '.submit-button'
    action  = action&.to_sym || context[:action] || DEFAULT_FORM_ACTION
    config  = form_actions.dig(action, :submit) || {}
    label ||= config[:label]

    prepend_css!(opt, css)
    opt[:title] ||= config.dig(:disabled, :tooltip)
    h.submit_tag(label, opt)
  end

  # Form cancel button.
  #
  # @param [String, Symbol, nil] action
  # @param [String, nil]         label    Override button label.
  # @param [String, Hash, nil]   url      Default: `#back_path`.
  # @param [Hash]                opt      To #button_tag / LinkHelper#make_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/model-form.js *cancelButton()*
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def cancel_button(action: nil, label: nil, url: nil, **opt)
    css     = '.cancel-button'
    action  = action&.to_sym || context[:action] || DEFAULT_FORM_ACTION
    config  = form_actions.dig(action, :cancel) || {}
    label ||= config[:label]

    prepend_css!(opt, css)
    opt[:title] ||= config[:tooltip]
    opt[:type]  ||= 'button'

    if opt[:'data-path'].present?
      button_tag(label, opt)
    else
      make_link(label, (url || back_path), **opt)
    end
  end

  # Data for hidden form fields.
  #
  # @param [Hash] opt
  #
  # @return [Hash{Symbol=>Any}]
  #
  # @yield [result] Add field value attributes.
  # @yieldparam [Hash] result
  # @yieldreturn [Hash]
  #
  def form_hidden(**opt)
    css = '.hidden-field'
    prepend_css!(opt, css)
    result = { redirect: h.last_operation_path || referrer }
    result = yield(result, opt) if block_given?
    result.map { |k, v|
      next if v.nil?
      v = opt.merge(id: k, name: k, value: v) unless v.is_a?(Hash)
      [k, v]
    }.compact.to_h
  end

  # Hidden form fields.
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Hash]                             opt   Passed to #form_hidden.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def form_hidden_fields(f, **opt)
    form_hidden(**opt).map { |k, v| f.hidden_field(k, v) }
  end

  # Form fields are wrapped in an element for easier grid manipulation.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def field_container(**opt)
    css = '.form-fields'
    prepend_css!(opt, css, model_type)
    html_div(opt) do
      form_fields << no_fields_row
    end
  end

  # Render pre-populated form fields.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #render_form_fields.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_fields(pairs: nil, **opt)
    pairs = model_form_fields.merge(pairs || {})
    render_form_fields(pairs: pairs, **opt)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Element name for field group radio buttons.
  #
  # @type [String]
  #
  FIELD_GROUP_NAME = 'field-group'

  # Control for filtering which fields are displayed.
  #
  # @param [Hash] opt                 Passed to #html_div for outer *div*.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #FIELD_GROUP
  # @see file:javascripts/feature/model-form.js *fieldDisplayFilterSelect()*
  #
  def field_group_controls(**opt)
    css  = '.field-group'
    name = FIELD_GROUP_NAME
    opt[:role] = 'radiogroup'

    # A label for the group (screen-reader only).
    legend = 'Filter input fields by state:' # TODO: I18n
    legend = html_tag(:legend, legend, class: 'sr-only')

    # Radio button controls.
    controls =
      field_groups.map do |group, properties|
        enabled = properties[:enabled].to_s
        next if false?(enabled)
        next if (enabled == 'debug') && !session_debug?

        tooltip  = properties[:tooltip]
        selected = true?(properties[:default])

        input = h.radio_button_tag(name, group, selected, role: 'radio')

        label = properties[:label] || group.to_s
        label = h.label_tag("#{name}_#{group}", label)

        html_div(class: 'radio', title: tooltip) { input << label }
      end
    return ''.html_safe if controls.blank?

    prepend_css!(opt, css)
    html_tag(:fieldset, legend, *controls, opt)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # Text for #no_fields_row. # TODO: I18n
  #
  # @type [String]
  #
  NO_FIELDS = 'NO FIELDS'

  # Hidden row that is shown only when no field rows are being displayed.
  #
  # @param [String]       label
  # @param [Boolean, nil] enable      If *true*, generate the element (enabled
  #                                     by default if #field_groups are used).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def no_fields_row(label: NO_FIELDS, enable: nil, **opt)
    css    = '.no-fields'
    enable = field_groups.present? if enable.nil?
    if enable
      prepend_css!(opt, css)
      html_div(label, opt)
    else
      ''.html_safe
    end
  end

  # Generate a marker which can indicate the status of an input field.
  #
  # @param [Symbol, Array<Symbol>] status   One or more of %[invalid required].
  # @param [String, Symbol]        label    Used with :required.
  # @param [Hash]                  opt      Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def status_marker(status: nil, label: nil, **opt)
    css    = '.status-marker'
    status = Array.wrap(status).compact
    entry  = status_markers.values_at(*status).first
    icon, tip = entry&.values_at(:label, :tooltip)
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
    opt[:'data-icon'] = icon ||= status_markers.dig(:blank, :label)
    prepend_css!(opt, css, *status)
    html_span(icon, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(Values)
  end

end

__loading_end(__FILE__)
