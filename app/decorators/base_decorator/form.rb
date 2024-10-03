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
      actions.map { [_1, config_button_values(_1)] }.to_h
    end

  end

  include Values

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  UNMODIFIABLE = config_term(:form, :unmodifiable).freeze

  # Render field/value pairs.
  #
  # @param [String, Symbol, nil] action
  # @param [String, nil]         separator    Def: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Hash]                opt          Passed to #render_form_pair
  #                                             except #VALUE_PAIRS_OPT
  #                                             to #value_pairs.
  #
  # @option opt [Integer] :index              Offset to make unique element IDs
  #                                             passed to #render_form_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # === Implementation Notes
  # Compare with BaseDecorator::List#render_field_values
  #
  def render_form_fields(action: nil, separator: nil, **opt)
    vp_opt = opt.extract!(*VALUE_PAIRS_OPT).compact_blank
    return ''.html_safe if blank? && vp_opt.blank?

    action    ||= context[:action]
    separator ||= DEFAULT_ELEMENT_SEPARATOR
    opt[:row]   = 0
    row_count   = nil
    trace_attrs!(opt, __method__)

    value_pairs(**vp_opt).map { |label, value|
      next if %i[file_data emma_data].include?(label)

      if label.is_a?(Symbol)
        field = label
        prop  = field_configuration(field, action)
        label = prop[:label] || labelize(label)
      elsif value.is_a?(Symbol)
        field = value
        prop  = field_configuration(field, action)
        label = prop[:label] || labelize(label)
        value = nil
      else
        prop  = field_configuration_for_label(label, action)
        field = prop[:field]
      end

      value = list_field_value(value, field: field)
      value = field_for(field, value: value.presence, prop: prop)

      # Update row based on the number of row(s) the previous pair displaced.
      opt[:row]  += (positive(row_count) || 1)
      row_count   = value.option[:row_count]

      opt[:field] = field
      opt[:prop]  = prop
      opt[:index] = (0 if prop[:readonly])
      render_form_pair(label, value, **opt)
    }.compact.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair.
  #
  # @param [String, Symbol]   label
  # @param [any, nil]         value
  # @param [FieldConfig, nil] prop        Default: from field/model.
  # @param [Symbol, nil]      field       For 'data-field' attribute.
  # @param [Integer, nil]     index       Offset for making unique element IDs.
  # @param [Integer, nil]     row         Display row.
  # @param [Integer, nil]     col         Display column.
  # @param [Integer, nil]     pos         Ordinal alternative to row or col.
  # @param [Boolean, nil]     disabled
  # @param [Boolean, nil]     required    For 'data-required' attribute.
  # @param [Boolean, nil]     no_label    Don't generate the label element.
  # @param [Boolean, nil]     no_help     Don't add help icon to the label.
  # @param [String, nil]      label_css
  # @param [String, nil]      value_css
  # @param [Hash]             opt         To label/value except:
  #
  # @option opt [Symbol] :render          Force render method.
  # @option opt [String] :base
  # @option opt [String] :label_id
  # @option opt [String] :value_id
  #
  # @return [ActiveSupport::SafeBuffer]   HTML label and value elements.
  # @return [nil]                         If *field* is :ignored or disallowed
  #                                         for the current user.
  #
  # === Implementation Notes
  # Compare with BaseDecorator::List#render_pair
  #
  # @see file:javascripts/feature/model-form.js *fieldLabel()*
  #
  def render_form_pair(
    label,
    value,
    prop:       nil,
    field:      nil,
    index:      nil,
    row:        nil,
    col:        nil,
    pos:        nil,
    disabled:   nil,
    required:   nil,
    no_label:   nil,
    no_help:    nil,
    label_css:  DEF_LABEL_CLASS,
    value_css:  DEF_VALUE_CLASS,
    **opt
  )
    prop  ||= field_configuration(field)
    field ||= prop[:field]
    label   = prop[:label]   || label
    return if prop[:ignored] || !user_has_role?(prop[:role])
    trace_attrs!(opt, __method__)

    # Pre-process label to derive names and identifiers.
    base    = opt.delete(:base) || model_html_id(field || label)
    name    = field&.to_s || base
    type    = "field-#{base}"
    base    = "Emma#{base}" if field == :emma_repository
    id_opt  = { base: base, index: index }.compact
    l_id    = opt.delete(:label_id)
    v_id    = opt.delete(:value_id) || field_html_id(value_css, **id_opt)

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

    # Special handling for password-related fields.
    if AccountConcern::PASSWORD_KEYS.include?(field)
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
    group         = (render_method == :render_form_menu_multi)
    file_data     = !opt.key?(:embed_uploader) || opt.delete(:embed_uploader)
    file_data   &&= (field == :file_data)
    input         = !group && !file_data

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
    prepend_css!(opt, "pos-#{pos}") if pos
    prepend_css!(opt, "col-#{col}") if col
    prepend_css!(opt, "row-#{row}") if row
    opt.merge!(row: row)            if row
    parts = []

    # Label for input element.
    if no_label || label.blank?
      l_id   = nil
    else
      l_id ||= field_html_id(label_css, **id_opt)
      l_opt  = prepend_css(opt, label_css)
      l_opt[:id]               = l_id
      l_opt[:status]           = status
      l_opt[:help]             = help     if help
      l_opt[:title]          ||= tooltip  if tooltip
      l_opt[:for]              = v_id     if input
      l_opt[:'data-label-for'] = v_id     if group
      l_opt[:tag]              = :div     if group || file_data
      # noinspection RubyMismatchedArgumentType
      parts << render_form_pair_label(field, label, **l_opt)
    end

    # Input element pre-populated with value.
    v_opt = prepend_css(opt, value_css)
    v_opt.merge!(id: v_id, name: name, base: "form-#{type}")
    v_opt[:title]             = UNMODIFIABLE if disabled
    v_opt[:readonly]          = true         if disabled # Not :disabled.
    v_opt[:placeholder]       = placeholder  if placeholder
    v_opt[:'data-field']      = field        if field
    v_opt[:'data-required']   = false        if optional
    v_opt[:'data-required']   = true         if required
    v_opt[:'aria-labelledby'] = l_id         if l_id
    v_opt[:range]             = range        if range
    # noinspection RubyMismatchedArgumentType
    parts << send(render_method, name, value, **v_opt)

    # Other content if provided.
    # noinspection RubyMismatchedArgumentType
    parts.concat Array.wrap(yield(field, raw_val, prop, **opt)) if block_given?

    safe_join(parts)
  end

  # Internal options for #render_form_pair_label.
  #
  # :tag    - Optional alternative to :label
  # :help   - To #help_popup
  # :status - To #status_marker
  #
  # @type [Array<Symbol>]
  #
  FORM_PAIR_LABEL_OPT = %i[tag status help row].freeze

  # Render the label for a label/value pair.
  #
  # @param [Symbol]      field
  # @param [String, nil] label
  # @param [String]      css        Characteristic CSS class/selector.
  # @param [Hash]        opt        To element tag except #FORM_PAIR_LABEL_OPT.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_pair_label(field, label = nil, css: DEF_LABEL_CLASS, **opt)
    local  = opt.extract!(*FORM_PAIR_LABEL_OPT)
    tag    = local[:tag] || :label
    help   = local[:help].presence
    status = local[:status].presence

    # Encapsulate the text in its own element to ensure separation from added
    # icon(s).
    if label.is_a?(ActiveSupport::SafeBuffer)
      # noinspection RubyMismatchedArgumentType
      text  = sanitized_string(label).squish
    else
      text  = (label || field).to_s
      label = labelize(field) unless label.is_a?(String)
      label = html_span(label, class: 'text')
    end

    # Include a help icon control if applicable.  (The associated popup panel
    # requires some special handling to get it to appear above other elements
    # that are in different stacking contexts.)
    if help.present?
      icon  = h.help_popup(*help, panel: { class: 'z-order-capture' })
      label = html_span { label << icon }
    end

    # Include status marker icon.
    if status.present?
      label << status_marker(status: status, label: text)
    end

    trace_attrs!(opt, __method__)
    append_css!(opt, 'fixed') if opt.delete(:fixed)
    append_css!(opt, css)
    if tag == :label
      h.label_tag(field, label, opt)
    else
      html_tag(tag, label, **opt)
    end
  end

  # @private
  UNSET_MENU_ITEM = config_term(:form, :unset).freeze

  # @private
  MENU_SINGLE_OPT = %i[name base fixed readonly constraints row].freeze

  # Single-select menu - dropdown.
  #
  # @param [String]      name
  # @param [Array]       value        Selected value(s) from `range#values`.
  # @param [Class,Array] range        A class derived from EnumType whose
  #                                     #values method will be used to populate
  #                                     the menu.
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt          Passed to #select_tag except for:
  #
  # @option opt [String]  :name       Overrides *name*
  # @option opt [String]  :base       Name and id for *select*; default: *name*
  # @option opt [Boolean] :fixed
  # @option opt [Boolean] :readonly
  # @option opt [Hash]    :constraints
  #
  # @raise [RuntimeError]             If *range* is not an EnumType.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/model-form.js *updateMenu()*
  #
  def render_form_menu_single(name, value, range:, css: '.menu.single', **opt)
    range.is_a?(Array) or valid_range?(range, fatal: true)
    normalize_attributes!(opt)
    local = opt.extract!(*MENU_SINGLE_OPT)
    field = opt[:'data-field']
    name  = local[:name] || name || local[:base] || field

    pairs =
      if range.is_a?(Class)
        p_opt = local[:constraints]&.dup || {}
        skip  = Array.wrap(p_opt.delete(:except)).map(&:to_s)
        range.pairs(**p_opt).except(*skip)
      end
    pairs ||= range.dup

    selected = Array.wrap(value).compact.presence || ['']
    menu =
      pairs.map do |item_value, item_label|
        item_value = item_value.to_s
        item_label = item_value.titleize if item_label.blank?
        [item_label, item_value]
      end
    menu.unshift([UNSET_MENU_ITEM, '']) unless menu.first.last.blank?
    menu = h.options_for_select(menu, selected)

    opt[:disabled] = true     if local[:readonly]
    append_css!(opt, 'fixed') if local[:fixed]
    prepend_css!(opt, css)
    h.select_tag(name, menu, opt)
  end

  # @private
  MENU_MULTI_OPT = %i[id name base fixed readonly inner outer row].freeze

  # Multi-select menu - scrollable list of checkboxes.
  #
  # @param [String] name
  # @param [Array]  value             Selected value(s) from `range#values`.
  # @param [Class]  range             A class derived from EnumType whose
  #                                     #values method will be used to populate
  #                                     the menu.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to inner group except for:
  #
  # @option opt [String]  :id
  # @option opt [String]  :name       Overrides *name*
  # @option opt [String]  :base       Name and id for *select*; default: *name*
  # @option opt [Boolean] :readonly
  # @option opt [Hash]    :inner
  # @option opt [Hash]    :outer
  #
  # @raise [RuntimeError]             If *range* is not an EnumType.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/feature/model-form.js *updateFieldsetCheckboxes()*
  #
  def render_form_menu_multi(name, value, range:, css: '.menu.multi', **opt)
    valid_range?(range, fatal: true)
    normalize_attributes!(opt)
    trace_attrs!(opt, __method__)
    local = opt.extract!(*MENU_MULTI_OPT)
    field = opt[:'data-field']
    name  = local[:name] || name || local[:base] || field

    # Checkbox elements.
    cb_opt   = trace_attrs_from(opt).merge!(role: 'option')
    selected = Array.wrap(value).compact.presence
    checkboxes =
      range.pairs.map do |item_value, item_label|
        cb_name          = "#{field}[]"
        cb_value         = item_value
        cb_opt[:id]      = [item_value, field, local[:id]].compact.join('-')
        cb_opt[:label]   = item_label
        cb_opt[:checked] = selected&.include?(item_value)
        render_check_box(cb_name, cb_value, **cb_opt)
      end

    # Grouped checkboxes.
    gr_opt = opt.except(:'data-field', :'data-required')
    gr_opt[:role]     = 'listbox'
    gr_opt[:name]     = name
    gr_opt[:multiple] = true
    gr_opt[:tabindex] = 0
    gr_opt.merge!(local[:inner]) if local[:inner].is_a?(Hash)
    group = html_ul(*checkboxes, **gr_opt)

    opt.delete(:'aria-labelledby')
    opt[:id]       = local[:id]
    opt[:name]     = name
    opt[:role]     = 'group'
    opt[:disabled] = true     if local[:readonly]
    opt.merge!(local[:outer]) if local[:outer].is_a?(Hash)
    append_css!(opt, 'fixed') if local[:fixed]
    prepend_css!(opt, css)
    html_div(**opt) { group }
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
    trace_attrs!(opt, __method__)
    append_css!(opt, 'fixed') if opt.delete(:fixed)
    prepend_css!(opt, css)
    render_form_field_item(name, value, **opt)
  end

  # render_form_input
  #
  # @param [String]   name
  # @param [any, nil] value
  # @param [String]   css             Characteristic CSS class/selector.
  # @param [Hash]     opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/feature/model-form.js *updateTextInputField()*
  #
  def render_form_input(name, value, css: '.input.single', **opt)
    trace_attrs!(opt, __method__)
    append_css!(opt, 'fixed') if opt.delete(:fixed)
    prepend_css!(opt, css)
    render_form_field_item(name, value, **opt)
  end

  # render_form_email
  #
  # @param [String]   name
  # @param [any, nil] value
  # @param [Hash]     opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_email(name, value, **opt)
    trace_attrs!(opt, __method__)
    render_form_input(name, value, **opt, type: :email)
  end

  # render_form_password
  #
  # @param [String]   name
  # @param [any, nil] value
  # @param [Hash]     opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_password(name, value, **opt)
    trace_attrs!(opt, __method__)
    render_form_input(name, value, **opt, type: :password)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Update `opt[:constraints]` based on the given range of values and the role
  # of the user.
  #
  # @param [Hash]     opt
  # @param [any, nil] range           Class; default: `opt[:range]`.
  #
  # @return [Hash]                    The possibly-modified *opt* argument.
  #
  def form_menu_role_constraints!(opt, range = nil)
    if (range ||= opt[:range]).is_a?(Class)
      add    = {}
      except = []

      if range == RolePrototype
        except << :anonymous # Not a valid role selection.
        except << :administrator << :developer  unless administrator?
        opt[:fixed] = true                      unless manager?

      elsif range == RoleCapability
        except << :administering << :developing unless administrator?

      elsif range < EnumType
        # No additional constraints for now.

      elsif administrator?
        case range.model_type
          when :user then add[:prepend] = { 0 => 'NONE' }
          when :org  then add[:prepend] = { 0 => 'NONE' }
        end

      elsif current_org
        case range.model_type
          when :user then add[:org]   = current_org
          when :org  then opt[:fixed] = true
        end
      end

      add[:except] = except if except.present?
      opt[:constraints] = opt[:constraints]&.merge(add) || add if add.present?
    end
    opt
  end

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
    trace_attrs!(opt, __method__)
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
    trace_attrs!(opt, __method__)
    html_span(filler, **opt)
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
    trace_attrs!(opt, __method__)
    html_italic("(#{note})", **opt)
  end

  # Options assumed to be related to a field element which are not retained by
  # elements related to it (for the purpose of field grouping).
  #
  # @type [Array<Symbol>]
  #
  RELATED_IGNORED_KEYS = %i[
    aria-describedby
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
  # :section:
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
  UPLOADER_CLASS = 'file-data-container'

  # The CSS class for the element displaying the name of an uploaded file.
  #
  # @type [String]
  #
  # @see file:javascripts/shared/uploader.js *BaseUploader.FILE_NAME_CLASS*
  #
  FILE_NAME_CLASS = 'uploaded-filename'

  # The CSS class which indicates that the element or its descendent(s) involve
  # reCAPTCHA verification.
  #
  # @type [String]
  #
  # @see file:javascripts/feature/model-form.js *RECAPTCHA_FORM_CLASS*
  #
  RECAPTCHA_FORM_CLASS = 'recaptcha-verification'

  # Generate a form with controls for entering field values and submitting.
  #
  # @param [String]        label      Label for the submit button.
  # @param [String,Symbol] action     Either :new or :edit.
  # @param [String]        cancel     URL for cancel button action (def: :back)
  # @param [Boolean]       uploader   If *true*, active client-side logic for
  #                                     supporting file upload.
  # @param [Boolean]       recaptcha  If *true*, verify with reCAPTCHA.
  # @param [Hash]          outer      Passed to outer div.
  # @param [String]        css        Characteristic CSS class/selector.
  # @param [Hash]          opt        Passed to #form_with.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/model-form.js *hasFileUploader()*
  #
  def model_form(
    label:      nil,
    action:     nil,
    cancel:     nil,
    uploader:   nil,
    recaptcha:  nil,
    outer:      nil,
    css:        '.model-form',
    **opt
  )
    action    = action&.to_sym || context[:action] || DEFAULT_FORM_ACTION
    classes   = [action, model_type]
    classes  << UPLOADER_CLASS       if uploader
    classes  << RECAPTCHA_FORM_CLASS if recaptcha

    trace_attrs!(opt, __method__)
    prepend_css!(opt, css, *classes)
    model_form_options!(opt, action: action)
    make_scroll_to_top_target!(opt)

    t_opt     = trace_attrs_from(opt)
    b_opt     = t_opt.merge(label: label, action: action, cancel: cancel)
    buttons   = form_buttons(**b_opt)

    outer_css = '.form-container'
    outer_opt = t_opt.merge(outer || {})
    prepend_css!(outer_opt, outer_css, *classes)
    html_div(**outer_opt) do
      form_with(model: object, **opt) do |f|
        parts  = form_hidden_fields(f)
        parts << form_top_controls(f, *buttons, **t_opt)
        parts << field_container(**t_opt)
        parts << h.recaptcha if recaptcha
        parts << form_bottom_controls(f, *buttons, **t_opt)
        safe_join(parts.compact, "\n")
      end
    end
  end

  # Label for line-editor update button.
  #
  # @type [String]
  #
  UPDATE_LABEL = config_term(:form, :update).freeze
  UPDATE_CSS   = 'update'

  # Label for line-editor cancel button.
  #
  # @type [String]
  #
  CANCEL_LABEL = config_term(:form, :cancel).freeze
  CANCEL_CSS   = 'cancel'

  # Generate a form for inline use.
  #
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [String]         css       Characteristic CSS class/selector.
  # @param [Hash]           opt       Passed to #form_with except
  #                                     #VALUE_PAIRS_OPT passed to
  #                                     #render_form_fields.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def model_line_editor(action: nil, css: '.line-editor', **opt)
    model_form_options!(opt, action: action)
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css)
    t_opt   = trace_attrs_from(opt)
    vp_opt  = opt.extract!(*VALUE_PAIRS_OPT)
    rff_opt = { action: action, no_label: true }
    form_with(model: object, **opt) do |f|
      parts  = form_hidden_fields(f)
      parts << render_form_fields(**rff_opt, **vp_opt, **t_opt)
      parts << html_button(UPDATE_LABEL, class: UPDATE_CSS, **t_opt)
      parts << html_button(CANCEL_LABEL, class: CANCEL_CSS, **t_opt)
      safe_join(parts)
    end
  end

  # ===========================================================================
  # :section:
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
  # :section:
  # ===========================================================================

  public

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
  # @yieldreturn [Array<String>, nil]
  #
  def form_top_controls(f = nil, *buttons, css: '.controls.top', **opt)
    trace_attrs!(opt, __method__)
    t_opt  = trace_attrs_from(opt)
    parts  = []
    parts << form_top_button_tray(f, *buttons, **t_opt)
    parts << field_group_controls(**t_opt)
    parts  = yield(parts) || parts if block_given?
    prepend_css!(opt, css)
    html_div(*parts, **opt)
  end

  # The form controls appearing above the fields.
  #
  # @param [ActionView::Helpers::FormBuilder, nil] f
  # @param [Array<ActiveSupport::SafeBuffer>]      buttons
  # @param [Hash]                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_top_button_tray(f = nil, *buttons, **opt, &blk)
    trace_attrs!(opt, __method__)
    form_button_tray(f, *buttons, **opt, &blk)
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
  # @yieldreturn [Array<String>, nil]
  #
  def form_bottom_controls(f = nil, *buttons, css: '.controls.bottom', **opt)
    trace_attrs!(opt, __method__)
    t_opt  = trace_attrs_from(opt)
    parts  = []
    parts << form_bottom_button_tray(f, *buttons, **t_opt)
    parts  = yield(parts) || parts if block_given?
    prepend_css!(opt, css)
    html_div(*parts, **opt)
  end

  # form_bottom_button_tray
  #
  # @param [ActionView::Helpers::FormBuilder, nil] f
  # @param [Array<ActiveSupport::SafeBuffer>]      buttons
  # @param [Hash]                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_bottom_button_tray(f = nil, *buttons, **opt, &blk)
    trace_attrs!(opt, __method__)
    form_button_tray(f, *buttons, **opt, &blk)
  end

  # A container including basic form controls.
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
  # @yieldreturn [Array<String>, nil]
  #
  def form_button_tray(f = nil, *buttons, css: '.button-tray', **opt)
    trace_attrs!(opt, __method__)
    t_opt  = trace_attrs_from(opt)
    fb_opt = opt.extract!(*FORM_BUTTONS_OPT)
    # noinspection RubyMismatchedArgumentType
    buttons.unshift(f) if f && !f.is_a?(ActionView::Helpers::FormBuilder)
    buttons = form_buttons(**fb_opt, **t_opt) if buttons.blank?
    buttons = yield(buttons) || buttons       if block_given?
    prepend_css!(opt, css)
    html_div(*buttons, **opt)
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
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>, nil]
  #
  def form_buttons(label: nil, cancel: nil, **opt)
    trace_attrs!(opt, __method__)
    opt[:action] ||= context[:action] || DEFAULT_FORM_ACTION
    buttons = []
    buttons << submit_button(label: label,  **opt)
    buttons << cancel_button(url:   cancel, **opt)
    block_given? && yield(buttons) || buttons
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
    trace_attrs!(opt, __method__)
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
    trace_attrs!(opt, __method__)
    form_button(:cancel, **opt)
  end

  # ===========================================================================
  # :section:
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
    prop   = form_actions.dig(action, type) || {}
    Log.warn("#{__method__}: no config for (#{action},#{type})") if prop.blank?

    state  = state&.to_s&.delete_prefix('if_')
    state  = (state || prop[:state] || :enabled).to_sym
    s_prop = prop[(state == :enabled) ? :if_enabled : :if_disabled] || {}

    label       ||= s_prop[:label]   || prop[:label]
    opt[:title] ||= s_prop[:tooltip] || prop[:tooltip]
    input_type    = opt[:type]       || type

    opt.reverse_merge!(disabled: true) if state == :disabled
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css, "#{type}-button")
    case
      when control.is_a?(Proc)     then control.call(label: label, **opt)
      when (input_type == :submit) then h.submit_tag(label, opt)
      when (input_type == :file)   then file_input_button(label, **opt)
      when url                     then make_link(url, label, **opt)
      else                              html_button(label, **opt)
    end
  end

  # @private
  FORM_BUTTON_OPT =
    method_key_params(:form_button).append(:type).excluding(:css).freeze

  # @private
  FORM_BUTTONS_OPT = [:cancel, *FORM_BUTTON_OPT].freeze

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

    i_opt = opt.extract!(:accept, :multiple, :value, :title)
    i_opt.merge!(id: i_id, class: 'file-input')
    input = h.file_field_tag(type, i_opt)

    label = h.label_tag(type, label, class: 'label', for: i_id)

    trace_attrs!(opt, __method__)
    html_div(**opt) do
      input << label
    end
  end

  # Data for hidden form fields.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [Hash]
  #
  # @yield [result] Add field value attributes.
  # @yieldparam [Hash] result
  # @yieldreturn [Hash]
  #
  def form_hidden(css: '.hidden-field', **opt)
    prepend_css!(opt, css)
    redir  = h.last_operation_path || referrer
    redir  = h.welcome_path if redir.blank? || redir.match?(%r{/sign_in[^/]*$})
    result = { redirect: redir }
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
    form_hidden(**opt).map { f.hidden_field(_1, _2) }
  end

  # Form fields are wrapped in an element for easier grid manipulation.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def field_container(css: '.form-fields', **opt)
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css, model_type)
    html_div(**opt) do
      t_opt = trace_attrs_from(opt)
      form_field_rows(**t_opt) << no_fields_row(**t_opt)
    end
  end

  # Render pre-populated form fields.
  #
  # @param [Hash] opt                 Passed to #render_form_fields.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_field_rows(**opt)
    trace_attrs!(opt, __method__)
    opt[:pairs] ||= model_form_fields
    render_form_fields(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Element name for field group radio buttons.
  #
  # @type [String]
  #
  FIELD_GROUP_NAME = 'field-group'
  FILTER_LEGEND    = config_term(:form, :filter).freeze

  # Control for filtering which fields are displayed.
  #
  # @param [String] name              Element name for controls.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_div for outer *div*.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/feature/model-form.js *fieldDisplayFilterSelect()*
  # @see file:app/assets/stylesheets/layouts/_root.scss *.wide-screen*, etc.
  #
  def field_group_controls(name: FIELD_GROUP_NAME, css: '.field-group', **opt)

    # Radio button controls.
    controls =
      field_groups.map { |group, properties|
        next unless user_has_role?(properties[:role])

        parts = []

        # Selection control.
        selected = true?(properties[:default])
        parts << h.radio_button_tag(name, group, selected, role: 'radio')

        # One or more label variants, only one of which will be visible
        # depending on the display form factor.
        narrow, medium, wide =
          properties.values_at(:label_narrow, :label_medium, :label_wide)
        l_cls   = ('wide-screen'       if wide || (narrow && medium))
        l_cls ||= ('not-narrow-screen' if narrow)
        wide  ||= properties[:label] || group.to_s
        parts << html_span(wide,   class: l_cls)
        parts << html_span(medium, class: 'medium-width')  if medium
        parts << html_span(narrow, class: 'narrow-screen') if narrow

        # The <label> element enclosing the <input> and label text variants.
        l_name = "#{name}_#{group}"
        l_opt  = { class: 'radio', title: properties[:tooltip] }
        h.label_tag(l_name, safe_join(parts), l_opt)
      }.compact
    return ''.html_safe if controls.blank?

    # A label for the group (screen-reader only).
    legend = html_legend(FILTER_LEGEND, class: 'sr-only')

    opt[:role]     = 'radiogroup'
    opt[:tabindex] = 0
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css)
    html_fieldset(legend, *controls, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Text for #no_fields_row.
  #
  # @type [String]
  #
  NO_FIELDS = config_term(:form, :no_fields).freeze
  THIS      = config_term(:form, :this).freeze

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
      trace_attrs!(opt, __method__)
      prepend_css!(opt, css)
      html_div(label, **opt)
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
      if tip.include?('%{This}')
        label &&= quote(label.to_s.sub(/[[:punct:]]+$/, ''))
        label ||= THIS.capitalize
        tip %= { This: label }
      end
      opt[:'data-title'] = tip
      opt[:title] ||= tip
    else
      opt[:'aria-hidden'] = true
    end
    opt[:'data-icon'] = icon ||= status_markers.dig(:blank, :label)
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css, *status)
    html_span(**opt) do
      t_opt = trace_attrs_from(opt)
      symbol_icon(icon, **t_opt)
    end
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
