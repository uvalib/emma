# app/decorators/base_decorator/form.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting the creation and modification of Model instances.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module BaseDecorator::Form

  include BaseDecorator::Common
  include BaseDecorator::Configuration
  include BaseDecorator::Fields
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

  # @private # TODO: I18n
  UNMODIFIABLE = 'System-generated; not modifiable.'

  # Render field/value pairs.
  #
  # @param [String, Symbol, nil] action
  # @param [Hash, nil]           pairs        Except #render_form_pair options.
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
  def render_form_fields(action: nil, pairs: nil, separator: nil, **opt)
    return ''.html_safe unless pairs || object
    action    ||= context[:action]
    separator ||= DEFAULT_ELEMENT_SEPARATOR
    opt[:row]   = 0
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
      # noinspection RubyMismatchedArgumentType
      render_form_pair(label, value, **opt)
    }.compact.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair.
  #
  # @param [String, Symbol] label
  # @param [*]              value
  # @param [Hash, nil]      prop        Default: from field/model.
  # @param [Symbol]         field       For 'data-field' attribute.
  # @param [Integer]        index       Offset for making unique element IDs.
  # @param [Integer]        row         Display row.
  # @param [Boolean]        disabled
  # @param [Boolean]        required    For 'data-required' attribute.
  # @param [Boolean]        no_label    Don't generate the label element.
  # @param [Boolean]        no_help     Don't add help icon to the label.
  # @param [String, nil]    label_css
  # @param [String, nil]    value_css
  # @param [Hash]           opt         To label/value except:
  #
  # @option opt [Symbol] :render        Force render method.
  #
  # @return [ActiveSupport::SafeBuffer] HTML label and value elements.
  # @return [nil]                       If *field* is :ignored or disallowed
  #                                       for the current user.
  #
  # == Implementation Notes
  # Compare with BaseDecorator::List#render_pair
  #
  def render_form_pair(
    label,
    value,
    prop:       nil,
    field:      nil,
    index:      nil,
    row:        nil,
    disabled:   nil,
    required:   nil,
    no_label:   nil,
    no_help:    nil,
    label_css:  DEFAULT_LABEL_CLASS,
    value_css:  DEFAULT_VALUE_CLASS,
    **opt
  )
    prop  ||= field_configuration(field)
    field ||= prop[:field]
    return if prop[:ignored]
    return if prop[:role] && !has_role?(prop[:role])

    # Pre-process label to derive names and identifiers.
    base = model_html_id(field || label)
    name = field&.to_s || base
    type = "field-#{base}"
    v_id = [type, index].compact.join('-')

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
    render_method = opt.delete(:render) if opt.key?(:render)

    # Update properties.
    disabled = prop[:readonly] if disabled.nil?
    required = prop[:required] if required.nil?
    help     = opt.delete(:help)
    help     = (help || prop[:help].presence unless no_help)
    tooltip  = opt.delete(:title) || prop[:tooltip]

    raw_val  = value
    value    = Array.wrap(value).compact_blank

    # Accumulate status values.
    status = []
    status << :required if required
    status << :disabled if disabled
    status << :invalid  if required && value.empty?
    status << :valid    if value.present?

    # Option settings for both label and value.
    prepend_css!(opt, type, *status)
    prepend_css!(opt, "row-#{row}") if row
    parts = []

    # Label for input element.
    l_id = nil
    unless no_label
      label = prop[:label] || label
      l_id  = label_css || DEFAULT_LABEL_CLASS
      l_id  = ["#{l_id}-#{base}", index].compact.join('-')
      l_opt = prepend_css(opt, label_css)
      l_opt.merge!(id: l_id, for: v_id, status: status)
      l_opt[:help]    = help    if help
      l_opt[:title] ||= tooltip if tooltip
      # noinspection RubyMismatchedArgumentType
      parts << render_form_pair_label(field, label, **l_opt)
    end

    # Input element pre-populated with value.
    v_opt = prepend_css(opt, value_css)
    v_opt.merge!(id: v_id, name: name)
    v_opt[:title]             = UNMODIFIABLE if disabled # TODO: I18n
    v_opt[:readonly]          = true         if disabled # Not :disabled.
    v_opt[:placeholder]       = placeholder  if placeholder
    v_opt[:'data-field']      = field        if field
    v_opt[:'data-required']   = false        if optional
    v_opt[:'data-required']   = true         if required
    v_opt[:'aria-labelledby'] = l_id         if l_id
    v_opt[:range]             = range        if range
    v_opt[:base]              = base
    parts << send(render_method, name, value, **v_opt)

    # Other content if provided.
    parts += Array.wrap(yield(field, raw_val, prop, **opt)) if block_given?

    safe_join(parts)
  end

  # Render the label for a label/value pair.
  #
  # @param [Symbol]                field
  # @param [String, nil]           label
  # @param [Symbol, Array<Symbol>] status
  # @param [Symbol, String, Array] help
  # @param [String]                css      Characteristic CSS class/selector.
  # @param [Hash]                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_pair_label(
    field,
    label,
    status: nil,
    help:   nil,
    css:    DEFAULT_LABEL_CLASS,
    **opt
  )
    # Encapsulate the text in its own element to ensure separation from added
    # icon(s).
    unless label.is_a?(ActiveSupport::SafeBuffer)
      label = labelize(field) unless label.is_a?(String)
      label = html_span(label, class: 'text')
    end

    # Include a help icon control if applicable.  (The associated popup panel
    # require some special handling to get it to appear above other elements
    # that are in different stacking contexts.)
    if help.present?
      icon  = h.help_popup(*help, panel: { class: 'z-order-capture' })
      label = html_span { label << icon }
    end

    # Include status marker icon.
    if status.present?
      marker = status_marker(status: status, label: label)
      label << marker
    end

    append_css!(opt, css)
    h.label_tag(field, label, opt)
  end

  # Single-select menu - drop-down.
  #
  # @param [String]      name
  # @param [Array]       value        Selected value(s) from `range#values`.
  # @param [Class|Array] range        A class derived from EnumType whose
  #                                     #values method will be used to populate
  #                                     the menu.
  # @param [String]      css          Characteristic CSS class/selector.
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
  def render_form_menu_single(name, value, range:, css: '.menu.single', **opt)
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
  # @param [String] css               Characteristic CSS class/selector.
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
  def render_form_menu_multi(name, value, range:, css: '.menu.multi', **opt)
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
        cb_opt[:id]      = [item_value, field, opt[:id]].compact.join('-')
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
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to :field_set_tag except for:
  #
  # @option [Boolean] :disabled       Passed to :render_form_input
  # @option [Integer] :count
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/feature/model-form.js *updateFieldsetInputs()*
  #
  def render_form_input_multi(name, value, css: '.input.multi', **opt)
    prepend_css!(opt, css)
    render_field_item(name, value, **opt)
  end

  # render_form_input
  #
  # @param [String] name
  # @param [*]      value
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/feature/model-form.js *updateTextInputField()*
  #
  def render_form_input(name, value, css: '.input.single', **opt)
    prepend_css!(opt, css)
    render_field_item(name, value, **opt)
  end

  # render_form_email
  #
  # @param [String] name
  # @param [*]      value
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
  # @param [*]      value
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
    opt = form_input_related_opt(css: 'label', **opt)
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
    opt = form_input_related_opt(css: 'note', **opt)
    opt[:separator] = ''
    html_tag(:em, opt) { "(#{note})" }
  end

  # Options assumed to be related to a field element which are not retained by
  # elements related to it (for the purpose of field grouping).
  #
  # @type [Array<Symbol>]
  #
  RELATED_IGNORED_KEYS = %i[
    aria-labelledby
    aria-required
    base
    data-field
    data-required
    id
    legend
    maxlength
    minlength
    name
    placeholder
    range
    readonly
    type
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
  def form_input_related_opt(css: nil, **opt)
    opt[:'data-for'] = opt.values_at(:'data-field', :'data-for').first
    opt.except!(*RELATED_IGNORED_KEYS)
    prepend_css!(opt, css) if css
    remove_css!(opt, 'value')
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Default action for #model_form if #context[:action] is not present.
  #
  # @type [Symbol]
  #
  DEFAULT_FORM_ACTION = :new

  # The CSS class which indicates that the element or its descendent(s) involve
  # file uploading.
  #
  # @type [String]
  #
  # @see file:javascripts/shared/uploader.js *BaseUploader.UPLOADER_CLASS*
  #
  UPLOADER_CLASS = 'file-uploader'

  # The CSS class for the element displaying the name of an uploaded file.
  #
  # @type [String]
  #
  # @see file:javascripts/shared/uploader.js *BaseUploader.FILE_NAME_CLASS*
  #
  FILE_NAME_CLASS = 'uploaded-filename'

  # Generate a form with controls for entering field values and submitting.
  #
  # @param [String]         label     Label for the submit button.
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [String]         cancel    URL for cancel button action (def: :back)
  # @param [Boolean]        uploader  If *true*, active client-side logic for
  #                                     supporting file upload.
  # @param [Hash]           outer     Passed to outer div.
  # @param [String]         css       Characteristic CSS class/selector.
  # @param [Hash]           opt       Passed to #form_with.
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
    css:      '.model-form',
    **opt
  )
    outer_css = '.form-container'
    uploader  = UPLOADER_CLASS if uploader.is_a?(TrueClass)
    action    = action&.to_sym || context[:action] || DEFAULT_FORM_ACTION
    classes   = [action, model_type, uploader]

    prepend_css!(opt, css, *classes)
    model_form_options!(opt, action: action)
    scroll_to_top_target!(opt)

    buttons   = form_buttons(label: label, action: action, cancel: cancel)
    outer_opt = prepend_css(outer, outer_css, *classes)
    html_div(outer_opt) do
      form_with(model: object, **opt) do |f|
        parts  = form_hidden_fields(f)
        parts << form_top_controls(f, *buttons)
        parts << field_container
        parts << form_bottom_controls(f, *buttons)
        safe_join(parts.compact, "\n")
      end
    end
  end

  # Label for line-editor update button. # TODO: I18n
  #
  # @type [String]
  #
  UPDATE_LABEL = 'Change'
  UPDATE_CSS   = 'update'

  # Label for line-editor cancel button. # TODO: I18n
  #
  # @type [String]
  #
  CANCEL_LABEL = 'Cancel'
  CANCEL_CSS   = 'cancel'

  # Generate a form for inline use.
  #
  # @param [Hash, nil]      pairs     Fields/values; default #model_form_fields
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [String]         css       Characteristic CSS class/selector.
  # @param [Hash]           opt       Passed to #form_with.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def model_line_editor(pairs: nil, action: nil, css: '.line-editor', **opt)
    pairs ||= model_form_fields
    prepend_css!(opt, css)
    model_form_options!(opt, action: action)
    form_with(model: object, **opt) do |f|
      parts  = form_hidden_fields(f)
      parts << render_form_fields(action: action, pairs: pairs, no_label: true)
      parts << html_button(UPDATE_LABEL, class: UPDATE_CSS)
      parts << html_button(CANCEL_LABEL, class: CANCEL_CSS)
      safe_join(parts)
    end
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # Modify a form options hash based on form action.
  #
  # @param [Hash, nil]      opt       The hash to modify (or create)
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [Hash]           other     Values to add to the hash.
  #
  # @return [Hash]                    The modified (or created) hash.
  #
  def model_form_options!(opt = nil, action: nil, **other)
    opt    = opt&.merge!(other) || other
    action = action&.to_sym || context[:action] || DEFAULT_FORM_ACTION
    case action
      when :edit
        opt[:method] ||= :put
        opt[:url]    ||= update_path
      when :new
        opt[:method] ||= :post
        opt[:url]    ||= create_path
      else
        Log.warn("#{self.class}.#{__method__}: #{action}: unexpected action")
    end
    opt[:multipart]    = true
    opt[:autocomplete] = 'off'
    # noinspection RubyMismatchedReturnType
    opt
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # @private
  FORM_BUTTON_OPTIONS = %i[action cancel label]

  # Control elements always visible at the top of the input form.
  #
  # @param [ActionView::Helpers::FormBuilder, nil] f
  # @param [Array<ActiveSupport::SafeBuffer>]      buttons
  # @param [String]                                css
  # @param [Hash]                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [parts] Extend or replace control elements.
  # @yieldparam [Array<ActiveSupport::SafeBuffer>] parts
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>]
  #
  def form_top_controls(f = nil, *buttons, css: '.controls.top', **opt)
    parts = [form_top_button_tray(f, *buttons), field_group_controls]
    parts = yield(parts) if block_given?
    prepend_css!(opt, css)
    html_div(*parts, opt)
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
  # @param [String]                                css
  # @param [Hash]                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [parts] Extend or replace control elements.
  # @yieldparam [Array<ActiveSupport::SafeBuffer>] parts
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>]
  #
  def form_bottom_controls(f = nil, *buttons, css: '.controls.bottom', **opt)
    parts = [form_bottom_button_tray(f, *buttons)]
    parts = yield(parts) if block_given?
    prepend_css!(opt, css)
    html_div(*parts, opt)
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
  # @param [String]                                css
  # @param [Hash]                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [parts] Extend or replace button tray elements.
  # @yieldparam [Array<ActiveSupport::SafeBuffer>] parts
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>]
  #
  def form_button_tray(f = nil, *buttons, css: '.button-tray', **opt)
    fb_opt = extract_hash!(opt, *FORM_BUTTON_OPTIONS)
    # noinspection RubyMismatchedArgumentType
    buttons.unshift(f) if f && !f.is_a?(ActionView::Helpers::FormBuilder)
    buttons = form_buttons(**fb_opt) if buttons.blank?
    buttons = yield(buttons)         if block_given?
    prepend_css!(opt, css)
    html_div(*buttons, opt)
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
  # @param [Hash] opt                 Passed to #form_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/model-form.js    *submitButton()*
  # @see file:app/assets/stylesheets/feature/_model_form.scss ".submit-button"
  #
  def submit_button(**opt)
    opt[:state] ||= :disabled
    form_button(:submit, **opt)
  end

  # Form cancel button.
  #
  # @param [Hash] opt                 Passed to #form_button.
  #
  # @option opt [String] :url         Passed to #make_link
  # @option opt [String] :'data-path' Passed to #html_button (supersedes :url)
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/model-form.js    *cancelButton()*
  # @see file:app/assets/stylesheets/feature/_model_form.scss ".cancel-button"
  #
  def cancel_button(**opt)
    if opt.key?(:'data-path')
      opt.delete(:url)
    else
      opt[:url] ||= back_path
    end
    form_button(:cancel, **opt)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # Generic form button.
  #
  # @param [Symbol]              type     The button configuration name.
  # @param [String, Symbol, nil] action
  # @param [Symbol]              state    Start state (:enabled/:disabled).
  # @param [String, nil]         label    Override button label.
  # @param [String, Hash, nil]   url      Invokes #make_link if present.
  # @param [Proc]                control  Optional button creator.
  # @param [String]              css      Characteristic CSS class/selector.
  # @param [Hash]                opt      Passed to #submit_tag.
  #
  # @option opt [Symbol] :type            Input type (default *type*).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/model-form.js *submitButton()*
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def form_button(
    type,
    action:   nil,
    state:    nil,
    label:    nil,
    url:      nil,
    control:  nil,
    css:      '.form-button',
    **opt
  )
    action = action&.to_sym || context[:action] || DEFAULT_FORM_ACTION
    config = form_actions.dig(action, type)

    if config.blank?
      Log.warn { "#{__method__}: no config for (#{action},#{type})" }
    else
      state       ||= config[:state]&.to_sym      || :enabled
      label       ||= config.dig(state, :label)   || config[:label]
      opt[:title] ||= config.dig(state, :tooltip) || config[:tooltip]
    end

    prepend_css!(opt, css, "#{type}-button")
    input_type = opt[:type] || type
    if control.is_a?(Proc)
      control.call(label: label, **opt)
    elsif input_type == :submit
      h.submit_tag(label, opt)
    elsif input_type == :file
      file_input_button(label, **opt)
    elsif url
      make_link(label, url, **opt)
    else
      html_button(label, opt)
    end
  end

  # file_input_button
  #
  # @param [String] label
  # @param [String] id          For input field
  # @param [String] type        Input field type
  # @param [Hash]   opt         To outer div except for #file_field_tag options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def file_input_button(label, id: nil, type: 'file', **opt)
    i_id  = id || unique_id(type)
    l_id  = "label-#{i_id}"

    i_opt = extract_hash!(opt, :accept, :multiple, :value, :title)
    i_opt.merge!(id: i_id, 'aria-labelledby': l_id, class: 'file-input')
    input = h.file_field_tag(type, i_opt)

    l_opt = { id: l_id, class: 'label' }
    label = html_div(label, l_opt)

    html_div(opt) do
      input << label
    end
  end

  # Data for hidden form fields.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [Hash{Symbol=>*}]
  #
  # @yield [result] Add field value attributes.
  # @yieldparam [Hash] result
  # @yieldreturn [Hash]
  #
  def form_hidden(css: '.hidden-field', **opt)
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
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def field_container(css: '.form-fields', **opt)
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
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_div for outer *div*.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #FIELD_GROUP
  # @see file:javascripts/feature/model-form.js *fieldDisplayFilterSelect()*
  # @see file:app/assets/stylesheets/layouts/_root.scss *.wide-screen*, etc.
  #
  def field_group_controls(css: '.field-group', **opt)
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

        parts = []

        # Selection control.
        selected = true?(properties[:default])
        parts << h.radio_button_tag(name, group, selected, role: 'radio')

        # One or more label variants, only one of which will be visible
        # depending on the display form factor.
        l_name = "#{name}_#{group}"
        narrow, medium, wide =
          properties.values_at(:label_narrow, :label_medium, :label_wide)
        parts << h.label_tag(l_name, narrow, class: 'narrow-screen') if narrow
        parts << h.label_tag(l_name, medium, class: 'medium-width')  if medium
        label = wide || properties[:label] || group.to_s
        l_opt = {}
        l_opt[:class] ||= ('wide-screen'       if wide || (narrow && medium))
        l_opt[:class] ||= ('not-narrow-screen' if narrow)
        parts << h.label_tag(l_name, label, l_opt)

        html_div(*parts, class: 'radio', title: properties[:tooltip])
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
  # @param [String]       css         Characteristic CSS class/selector.
  # @param [Hash]         opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def no_fields_row(label: NO_FIELDS, enable: nil, css: '.no-fields', **opt)
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
  # @param [String]                css      Characteristic CSS class/selector.
  # @param [Hash]                  opt      Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def status_marker(status: nil, label: nil, css: '.status-marker', **opt)
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
