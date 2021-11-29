# app/helpers/entry_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the display and creation of Entry records,
# including support for file upload via Uppy.
#
module EntryHelper

  include Emma::Json
  include Emma::Unicode

  include ConfigurationHelper
  include I18nHelper
  include LinkHelper
  include ModelHelper
  include PopupHelper

  include Record::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Paths used by entry-form.js.                                                # NOTE: from UploadHelper::UPLOAD_PATH
  #
  # @type [Hash]
  #
  ENTRY_PATH = {
    index:    (ENTRY_URL = '/entry'), # GET /entry                              # NOTE from UploadHelper::UPLOAD_URL
    new:      "#{ENTRY_URL}/new",     # GET /entry/new
    edit:     "#{ENTRY_URL}/edit",    # GET /entry/edit
    create:   ENTRY_URL,              # POST /entry
    renew:    "#{ENTRY_URL}/renew",   # POST /entry/renew
    reedit:   "#{ENTRY_URL}/reedit",  # POST /entry/reedit
    cancel:   "#{ENTRY_URL}/cancel",  # POST /entry/cancel
    endpoint: "#{ENTRY_URL}/endpoint" # POST /entry/endpoint
  }.deep_freeze

  # CSS styles.                                                                 # NOTE: from UploadHelper::UPLOAD_STYLE
  #
  # @type [Hash]
  #
  ENTRY_STYLE = {
    drag_target: 'entry-drag_and_drop',
    preview:     'entry-preview',
  }.deep_freeze

  # Display preview of Shrine uploads.  NOTE: Not currently enabled.            # NOTE: from UploadHelper::UPLOAD_PREVIEW_ENABLED
  #
  # @type [Boolean]
  #
  ENTRY_PREVIEW_ENABLED = false

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether preview is enabled.
  #
  # == Usage Notes
  # Uppy preview is only for image files.
  #
  def preview_enabled?                                                          # NOTE: from UploadHelper
    ENTRY_PREVIEW_ENABLED
  end

  # Supply an element to contain a preview thumbnail of an image file.
  #
  # @param [Boolean] force
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If preview is not enabled.
  #
  def entry_preview(force = false)                                              # NOTE: from UploadHelper#upload_preview
    return unless force || preview_enabled?
    html_div('', class: ENTRY_STYLE[:preview])
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default link tooltip.                                                       # NOTE: from UploadHelper::UPLOAD_SHOW_TOOLTIP
  #
  # @type [String]
  #
  ENTRY_SHOW_TOOLTIP = I18n.t('emma.entry.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Entry] item
  # @param [Hash]  opt                Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_link(item, **opt)                                                  # NOTE: from UploadHelper
    opt[:path]    = show_entry_path(id: item.id)
    opt[:tooltip] = ENTRY_SHOW_TOOLTIP
    model_link(item, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render the contents of the :file_data field.
  #
  # @param [Model, Hash, nil] item
  # @param [Hash]             opt
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If *item* did not have :file_data.
  #
  # @see #render_json_data
  #
  # noinspection RailsParamDefResolve
  def render_file_data(item, **opt)                                             # NOTE: from UploadHelper
    data = item.try(:file_data) || item.try(:[], :file_data) or return
    render_json_data(item, data, **opt)
  end

  # Render the contents of the :emma_data field.
  #
  # @param [Model, Hash, nil] item
  # @param [Hash]             opt
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If *item* did not have :emma_data.
  #
  # @see #render_json_data
  #
  # noinspection RailsParamDefResolve
  def render_emma_data(item, **opt)                                             # NOTE: from UploadHelper
    data  = item.try(:emma_data) || item.try(:[], :emma_data) or return
    pairs = json_parse(data)
    pairs&.transform_keys! { |k| Model::SEARCH_RECORD_LABELS[k] || k }
    render_json_data(item, pairs, **opt)
  end

  # Render hierarchical data.
  #
  # @param [Model, Hash, nil]  item
  # @param [String, Hash, nil] value
  # @param [Hash]              opt        Passed to #render_field_values
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If *value* was not valid JSON.
  #
  def render_json_data(item, value, **opt)                                      # NOTE: from UploadHelper
    return unless item
    opt[:model]     ||= Model.for(item)
    opt[:no_format] ||= :dc_description

    pairs = json_parse(value).presence
    pairs&.transform_values! do |v|
      v.is_a?(Hash) ? render_json_data(item, v, **opt) : v
    end
    pairs &&= render_field_values(item, pairs: pairs, **opt)
    pairs ||= render_empty_value(EMPTY_VALUE)

    # noinspection RubyMismatchedParameterType
    html_div(pairs, class: 'data-list')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Model, Hash] item
  # @param [*]           value
  # @param [Hash]        opt          Passed to the render method.
  #
  # @return [Field::Type]
  # @return [String]
  # @return [nil]
  #
  # @see ModelHelper::List#render_value
  #
  def entry_render_value(item, value, **opt)                                    # NOTE: from UploadHelper#upload_render_value
    if value.is_a?(Symbol)
      if item.is_a?(Record::EmmaData) && item.include?(value)
        case value
          when :file_data then render_file_data(item, **opt)
          when :emma_data then render_emma_data(item, **opt)
          else                 item[value] || EMPTY_VALUE
        end
      else
        Field.for(item, value)
      end
    end || render_value(item, value, **opt)
  end

  alias_method :phase_render_value,  :entry_render_value # TODO: if item.is_a?(Phase) is required...
  alias_method :action_render_value, :entry_render_value # TODO: if item.is_a?(Action) is required...

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render entry attributes.                                                    # NOTE: from UploadHelper#upload_details
  #
  # @param [Entry]     item
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #model_details.
  #
  def entry_details(item, pairs: nil, **opt)
    opt[:model] = model = item && Model.for(item) || :entry
    opt[:pairs] = Model.show_fields(model).merge(pairs || {})
    model_details(item, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Groupings of states related by theme.                                       # NOTE: from UploadHelper::UPLOAD_STATE_GROUP
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/controllers/entry.en.yml *en.emma.entry.state_group*
  #
  ENTRY_STATE_GROUP =
    Record::Steppable::STATE_GROUP.transform_values do |entry|
      entry.map { |key, value|
        if %i[enabled show].include?(key)
          if value.nil? || true?(value)
            value = true
          elsif false?(value)
            value = false
          elsif value == 'nonzero'
            value =
              ->(list, group = nil) {
=begin # TODO: Entry.phases have state - Entry doesn't
                list &&= list.select { |r| r.state_group == group } if group
                list.present?
=end
              }
          end
        end
        [key, value]
      }.to_h
    end

  # CSS class for the entry state selection panel.                              # NOTE: from UploadHelper::UPLOAD_GROUP_PANEL_CLASS
  #
  # @type [String]
  #
  ENTRY_GROUP_PANEL_CLASS = 'entry-select-group-panel'

  # CSS class for the state group controls container.                           # NOTE: from UploadHelper::UPLOAD_GROUP_CLASS
  #
  # @type [String]
  #
  ENTRY_GROUP_CLASS = 'entry-select-group'

  # CSS class for a control within the entry state selection panel.             # NOTE: from UploadHelper::UPLOAD_GROUP_CONTROL_CLASS
  #
  # @type [String]
  #
  ENTRY_GROUP_CONTROL_CLASS = 'control'

  # Select Entry records based on workflow state group.
  #
  # @param [Hash] counts              A table of group names associated with
  #                                     their overall totals (default:
  #                                     @group_counts).
  # @param [Hash] opt                 Passed to inner #html_div except for:
  #
  # @option opt [String]        :curr_path    Default: `request.fullpath`
  # @option opt [String,Symbol] :curr_group   Default from `request_parameters`
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #ENTRY_STATE_GROUP
  # @see file:app/assets/javascripts/feature/records.js *filterPageDisplay()*
  #
  # == Usage Notes
  # This is invoked from ModelHelper::List#page_filter.
  #
  def entry_state_group_select(counts: nil, **opt)                              # NOTE: from UploadHelper#upload_state_group_select
    css_selector = ENTRY_GROUP_PANEL_CLASS
    curr_path  = opt.delete(:curr_path)  || request.fullpath
    curr_group = opt.delete(:curr_group) || request_parameters[:group] || :all
    curr_group = curr_group.to_sym if curr_group.is_a?(String)
    counts   ||= @group_counts || {}

    # A label preceding the group of buttons (screen-reader only).
    p_id   = "label-#{ENTRY_GROUP_CLASS}"
    prefix = 'Select records based on their submission state:' # TODO: I18n
    prefix = html_div(prefix, id: p_id, class: 'sr-only')

    # Create buttons for each state group that has entries.
    buttons =
      ENTRY_STATE_GROUP.map do |group, properties|
        all     = (group == :all)
        count   = counts[group] || 0
        enabled = all || count.positive?
        next unless enabled || session_debug?

        label = properties[:label] || group
        label = html_span(label, class: 'label')
        label << html_span("(#{count})", class: 'count')

        base  = entry_index_path
        url   = all ? base : entry_index_path(group: group)

        link_opt = {
          class:        ENTRY_GROUP_CONTROL_CLASS,
          'aria-label': properties[:tooltip],
          'data-group': group
        }
        prepend_classes!(link_opt, 'control-button')
        append_classes!(link_opt, 'current')  if group == curr_group
        append_classes!(link_opt, 'disabled') if url   == curr_path
        append_classes!(link_opt, 'hidden')   unless enabled
        make_link(label, url, link_opt)
      end

    # Wrap the controls in a group.
    prepend_classes!(opt, ENTRY_GROUP_CLASS)
    opt[:role]              = 'navigation'
    opt[:'aria-labelledby'] = p_id
    group = html_div(*buttons, opt)

    # An element following the group to hold a dynamic description of the group
    # button currently hovered/focused.  (@see javascripts/feature/records.js)
    note = html_div('&nbsp;'.html_safe, class: 'note', 'aria-hidden': true)
    note = html_div(note, class: 'note-tray', 'aria-hidden': true)

    # Include the group and note area in a panel.
    html_div(class: css_classes(css_selector)) do
      prefix << group << note
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Control whether in-page filtering is allowed.                               # NOTE: from UploadHelper::UPLOAD_PAGE_FILTERING
  #
  # @type [Boolean]
  #
  ENTRY_PAGE_FILTERING = false

  # CSS class for the state group page filter panel.                            # NOTE: from UploadHelper::UPLOAD_PAGE_FILTER_CLASS
  #
  # @type [String]
  #
  ENTRY_PAGE_FILTER_CLASS = 'entry-page-filter-panel'

  # CSS class for the state group controls container.                           # NOTE: from UploadHelper::UPLOAD_FILTER_GROUP_CLASS
  #
  # @type [String]
  #
  ENTRY_FILTER_GROUP_CLASS = 'entry-filter-group'

  # CSS class for a control within the state group controls container.          # NOTE: from UploadHelper::UPLOAD_FILTER_CONTROL_CLASS
  #
  # @type [String]
  #
  ENTRY_FILTER_CONTROL_CLASS = 'control'

  # Control for filtering which records are displayed.
  #
  # @param [Array<Entry>] list        Default: `#page_items`.
  # @param [Hash]         counts      A table of group names associated with
  #                                     their overall totals (default:
  #                                     @group_counts).
  # @param [Hash]         opt         Passed to inner #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If #ENTRY_PAGE_FILTERING is *false*.
  #
  # @see #ENTRY_STATE_GROUP
  # @see file:app/assets/javascripts/feature/records.js *filterPageDisplay()*
  #
  # == Usage Notes
  # This is invoked from ModelHelper::List#page_filter.
  #
  def entry_page_filter(*list, counts: nil, **opt)                              # NOTE: from UploadHelper#upload_page_filter
    return unless ENTRY_PAGE_FILTERING
    css_selector = ENTRY_PAGE_FILTER_CLASS
    name     = __method__.to_s
    counts ||= @group_counts || {}
    list     = page_items if list.blank?
    table    = list.group_by(&:state_group)

    # Create radio button controls for each state group that has entries.
    controls =
      ENTRY_STATE_GROUP.map do |group, properties|
        items   = table[group]  || []
        all     = (group == :all)
        count   = counts[group] || (all ? list.size : items.size)
        enabled = all || count.positive?
        # noinspection RubyMismatchedParameterType
        enabled ||= active_state_group?(nil, properties, items)
        next unless enabled || session_debug?

        input_id = "#{name}-#{group}"
        label_id = "label-#{input_id}"
        tooltip  = properties[:tooltip]
        selected = true?(properties[:default])

        i_opt = { role: 'radio' }
        input = radio_button_tag(name, group, selected, i_opt)

        l_opt = { id: label_id }
        label = ERB::Util.h(properties[:label] || group.to_s)
        label = "#{label}&thinsp;(#{count})".html_safe if count
        label = label_tag(input_id, label, l_opt)

        html_opt = {
          class:        ENTRY_FILTER_CONTROL_CLASS,
          title:        tooltip,
          'data-group': group
        }
        append_classes!(html_opt, 'hidden') unless enabled
        html_div(html_opt) { input << label }
      end

    # Text before the radio buttons:
    prefix = 'On this page:' # TODO: I18n
    prefix = html_span(prefix, class: 'prefix', 'aria-hidden': true)
    controls.unshift(prefix)

    # Wrap the controls in a group.
    prepend_classes!(opt, ENTRY_FILTER_GROUP_CLASS)
    opt[:role] = 'radiogroup'
    group = html_div(controls, opt)

    # A label for the group (screen-reader only).
    legend = 'Choose the entry submission state to display:' # TODO: I18n
    legend = html_tag(:legend, legend, class: 'sr-only')

    # Include the group in a panel with accompanying label.
    outer_opt = { class: css_classes(css_selector) }
    append_classes!(outer_opt, 'hidden') if controls.size <= 1
    field_set_tag(nil, outer_opt) do
      legend << group
    end
  end

  alias_method :phase_page_filter,  :entry_page_filter # TODO: ...
  alias_method :action_page_filter, :entry_page_filter # TODO: ...

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # CSS class for the debug-only panel of checkboxes to control filter          # NOTE: from UploadHelper::UPLOAD_FILTER_OPTIONS_CLASS
  # visibility.
  #
  # @type [String]
  #
  ENTRY_FILTER_OPTIONS_CLASS = 'entry-filter-options-panel'

  # Control the selection of filters displayed by #entry_page_filter.
  #
  # @param [Array<Entry>] list        Default: `#page_items`.
  # @param [Hash]         opt         Passed to #html_div for outer <div>.
  #
  # @option opt [Array] :records      List of upload records for display.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/records.js *filterOptionToggle()*
  #
  def entry_page_filter_options(*list, **opt)                                   # NOTE: from UploadHelper#upload_page_filter_options
    css_selector = ENTRY_FILTER_OPTIONS_CLASS
    name     = __method__.to_s
    counts ||= @group_counts || {}
    list     = page_items if list.blank? && counts.blank?

    # A label preceding the group (screen-reader only).
    legend = 'Select/de-select state groups to show' # TODO: I18n
    legend = html_tag(:legend, legend, class: 'sr-only')

    # Checkboxes.
    cb_opt = { class: ENTRY_FILTER_CONTROL_CLASS }
    groups = { ALL_FILTERS: { label: 'Show all filters', checked: false } }
    groups.merge!(ENTRY_STATE_GROUP)
    checkboxes =
      groups.map do |group, properties|
        cb_name  = "[#{name}][]"
        cb_value = group
        checked  = properties[:checked]
        checked  = counts[group]&.positive?                     if checked.nil?
        checked  = active_state_group?(group, properties, list) if checked.nil?
        cb_opt[:checked] = checked
        cb_opt[:label]   = %Q(Show "#{properties[:label]}") # TODO: I18n
        cb_opt[:id]      = "#{name}-#{cb_value}"
        render_check_box(cb_name, cb_value, **cb_opt)
      end

    prepend_classes!(opt, css_selector)
    html_tag(:fieldset, legend, *checkboxes, opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  protected

  # Indicate whether the state group described by *properties* should be an
  # active state group selection.
  #
  # @param [Symbol, nil]       group
  # @param [Hash, nil]         properties
  # @param [Array<Entry>, nil] list
  #
  def active_state_group?(group, properties, list)                              # NOTE: from UploadHelper
    return true if properties.blank?
    %i[enabled show].all? do |k|
      case (v = properties[k])
        when 'debug' then session_debug?
        when Proc    then v.call(list, group)
        else              v
      end
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # CSS class for the containing of a listing of Entry records.                 # NOTE: from UploadHelper::UPLOAD_LIST_CLASS
  #
  # @type [String]
  #
  ENTRY_LIST_CLASS = 'entry-list'

  # Render a single entry for use within a list of items.                       # NOTE: from UploadHelper#upload_list_item
  #
  # @param [Entry]     item
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #model_list_item.
  #
  def entry_list_item(item, pairs: nil, **opt)
    opt[:model] = model = item && Model.for(item) || :entry
    opt[:pairs] = Model.index_fields(model).merge(pairs || {})
    model_list_item(item, **opt)
  end

  # Include control icons below the entry number.
  #
  # @param [Entry] item
  # @param [Hash]  opt                Passed to #list_item_number.
  #
  def entry_list_item_number(item, **opt)                                       # NOTE: from UploadHelper#upload_list_item_number
    list_item_number(item, **opt) do
      entry_control_icons(item)
    end
  end

  # Text for #entry_no_records_row. # TODO: I18n                                # NOTE: from UploadHelper::UPLOAD_NO_RECORDS
  #
  # @type [String]
  #
  ENTRY_NO_RECORDS = 'NO RECORDS'

  # Hidden row that is shown only when no field rows are being displayed.
  #
  # @param [Hash] opt                 Passed to created elements.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def entry_no_records_row(**opt)                                               # NOTE: from UploadHelper#upload_no_records_row
    css_selector = '.no-records'
    prepend_classes!(opt, css_selector)
    # noinspection RubyMismatchedReturnType
    html_div('', opt) << html_div(ENTRY_NO_RECORDS, opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Entry operation icon definitions.                                           # NOTE: from UploadHelper::UPLOAD_ICONS
  #
  # @type [Hash{Symbol=>Hash{Symbol=>*}}]
  #
  ENTRY_CONTROL_ICONS = {
    check: {
      icon:    BANG,
      tip:     'Check for an update to the status of this submission', # TODO: I18n
      path:    :check_entry_path,
      enabled: ->(item) { item.try(:in_process?) },
    },
    edit: {
      icon:    DELTA,
      tip:     'Modify this EMMA entry', # TODO: I18n
      enabled: true,
    },
    delete: {
      icon:    HEAVY_X,
      tip:     'Delete this EMMA entry', # TODO: I18n
      enabled: true,
    }
  }.deep_freeze

  # Generate an element with icon controls for the operation(s) the user is
  # authorized to perform on the entry.
  #
  # @param [Entry] item
  # @param [Hash]  opt                  Passed to #entry_control_icon
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       If no operations are authorized.
  #
  # @see #ENTRY_CONTROL_ICONS
  #
  def entry_control_icons(item, **opt)                                          # NOTE: from UploadHelper#upload_entry_icons
    css_selector = '.icon-tray'
    icons =
      # @type [Symbol] operation
      # @type [Hash]   properties
      ENTRY_CONTROL_ICONS.map { |operation, properties|
        next unless can?(operation, item)
        action_opt = properties.merge(opt)
        action_opt[:item] ||= (item if item.is_a?(Model)) # TODO: should this just be Entry?
        entry_control_icon(operation, **action_opt)
      }.compact
    html_span(icons, class: css_classes(css_selector)) if icons.present?
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  protected

  # Produce an Entry action icon based on either :path or :id.
  #
  # @param [Symbol] op                    One of #ENTRY_CONTROL_ICONS.keys.
  # @param [Hash]   opt                   Passed to #make_link except for:
  #
  # @option opt [Entry]         :item
  # @option opt [String]        :id
  # @option opt [String, Proc]  :path
  # @option opt [String]        :icon
  # @option opt [String]        :tip
  # @option opt [Boolean, Proc] :enabled
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML link element.
  # @return [nil]                         If *item* unrelated to a submission.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def entry_control_icon(op, **opt)                                             # NOTE: from UploadHelper#upload_action_icon
    css_selector = '.icon'
    item         = opt.delete(:item)
    model        = opt.delete(:model) || Model.for(item)
    id           = opt.delete(:id)    || item.try(:id)
    case (enabled = opt.delete(:enabled))
      when nil         then # Enabled if not specified otherwise.
      when true, false then return unless enabled
      when Proc        then return unless enabled.call(item)
      else                  return unless true?(enabled)
    end
    case (path = opt.delete(:path))
      when Symbol then # deferred
      when Proc   then path = path.call(item)
      else             path ||= (get_path_for(model, op, id: id) if id)
    end
    return if path.blank?
    icon = opt.delete(:icon) || STAR
    tip  = opt.delete(:tip)
    opt[:title] ||= tip
    # noinspection RubyMismatchedParameterType
    if op == :check
      opt[:icon] ||= icon
      check_status_popup(item, path, **opt)
    else
      make_link(icon, path, **prepend_classes!(opt, css_selector, op))
    end
  end

  # Create a container with the repository ID displayed as a link but acting as
  # a popup toggle button and a popup panel which is initially hidden.
  #
  # @param [Entry]          item
  # @param [String, Symbol] path
  # @param [Hash]           opt         Passed to #popup_container except for:
  #
  # @option opt [Hash] :attr            Options for deferred content.
  # @option opt [Hash] :placeholder     Options for transient placeholder.
  #
  # @see file:app/assets/javascripts/feature/popup.js *togglePopup()*
  #
  def check_status_popup(item, path, **opt)                                     # NOTE: from UploadHelper
    css_selector = '.check-status-popup'
    icon   = opt.delete(:icon)
    ph_opt = opt.delete(:placeholder)
    attr   = opt.delete(:attr)&.dup || {}
    id     = item.id
    css_id = opt[:'data-iframe'] || attr[:id] || "popup-frame-#{id}"
    path   = send(path, id: id, modal: true) if path.is_a?(Symbol)

    opt[:'data-iframe'] = attr[:id] = css_id
    opt[:title]   ||= 'Check the status of this submission' # TODO: I18n
    opt[:control] ||= {}
    opt[:control][:icon] ||= icon
    opt[:panel]  = append_classes(opt[:panel], 'refetch z-order-capture')
    opt[:resize] = false unless opt.key?(:resize)

    popup_container(**prepend_classes!(opt, css_selector)) do
      ph_opt = prepend_classes(ph_opt, 'iframe', POPUP_DEFERRED_CLASS)
      ph_txt = ph_opt.delete(:text) || 'Checking...' # TODO: I18n
      ph_opt[:'data-path'] = path
      ph_opt[:'data-attr'] = attr.to_json
      html_div(ph_txt, ph_opt)
    end
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Render pre-populated form fields.                                           # NOTE: from UploadHelper#upload_form_fields
  #
  # @param [Entry]     item
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #render_form_fields.
  #
  def entry_form_fields(item, pairs: nil, **opt)
    opt[:model] = model = item && Model.for(item) || :entry
    opt[:pairs] = Model.form_fields(model).merge(pairs || {})
    render_form_fields(item, **opt)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Button information for entry actions.                                       # NOTE: from UploadHelper::UPLOAD_ACTION_VALUES
  #
  # @type [Hash{Symbol=>Hash}]
  #
  ENTRY_ACTION_VALUES =
    %i[new edit delete bulk_new bulk_edit bulk_delete].map { |action|
      [action, config_button_values(:entry, action)]
    }.to_h.deep_freeze

  # Screen-reader-only label for file input.  (This is to satisfy accessibility # NOTE: from UploadHelper
  # checkers which don't ignore the file input which is made invisible in favor
  # of the Uppy file input control).
  #
  # @type [String]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  FILE_LABEL = I18n.t('emma.entry.new.select.label').freeze

  # Generate a form with controls for uploading a file, entering metadata, and
  # submitting.
  #
  # @param [Entry]          item
  # @param [String]         label     Label for the submit button.
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [Hash]           opt       Passed to #form_with except for:
  #
  # @option opt [String] :cancel      URL for cancel button action (default:
  #                                     :back).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def entry_form(item, label: nil, action: nil, **opt)                          # NOTE: from UploadHelper#upload_form
    css_selector = '.entry-form'
    action ||= params[:action]
    cancel   = opt.delete(:cancel)

    # noinspection RubyCaseWithoutElseBlockInspection
    case action
      when :new
        opt[:url]      = create_entry_path
      when :edit
        opt[:url]      = update_entry_path
        opt[:method] ||= :put
    end
    opt[:multipart]    = true
    opt[:autocomplete] = 'off'

    prepend_classes!(opt, css_selector, action)
    scroll_to_top_target!(opt)

    html_div(class: "entry-form-container #{action}") do
      # @type [ActionView::Helpers::FormBuilder] f
      form_with(model: item, **opt) do |f|
        data_opt = { class: 'hidden-field' }

        # Extra information to support reverting the record when canceled.
        #rev_data = item&.get_revert_data&.to_json # TODO: is this still needed?
        rev_data  = '' # TODO: ??? (The only relevant Upload field would be :updated_at)
        rev_data  = data_opt.merge!(id: 'revert_data', value: rev_data)
        rev_data  = f.hidden_field(:revert_data, rev_data)

        # Communicate :file_data through the form as a hidden field.
        file_data = item&.file_data
        file_data = data_opt.merge!(id: 'entry_file_data', value: file_data)
        file_data = f.hidden_field(:file, file_data)

        # Hidden data fields.
        emma_data = item&.emma_data
        emma_data = data_opt.merge!(id: 'entry_emma_data', value: emma_data)
        emma_data = f.hidden_field(:emma_data, emma_data)

        # Control elements which are always visible at the top of the input
        # form.
        controls =
          html_div(class: 'controls') do
            # Button tray.
            tray = []
            tray << entry_submit_button(action: action, label: label)
            tray << entry_cancel_button(action: action, url: cancel)
            tray << f.label(:file, FILE_LABEL, class: 'sr-only', id: 'fi_label')
            tray << f.file_field(:file)
            tray << uploaded_filename_display
            tray = html_div(class: 'button-tray') { tray }

            # Field display selections.
            tabs = entry_field_group

            # Parent entry input control.
            parent_input = parent_entry_select

            tray << tabs << parent_input
          end

        # Form fields.
        fields = entry_field_container(item)

        # Convenience submit and cancel buttons below the fields.
        bottom =
          html_div(class: 'controls') do
            tray = []
            tray << entry_submit_button(action: action, label: label)
            tray << entry_cancel_button(action: action, url: cancel)
            html_div(class: 'button-tray') { tray }
          end

        # All form sections.
        sections = [emma_data, file_data, rev_data, controls, fields, bottom]
        safe_join(sections, "\n")
      end
    end
  end

  # Entry submit button.
  #
  # @param [Hash] opt                 Passed to #form_submit_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/download.js *submitButton()*
  #
  def entry_submit_button(**opt)                                                # NOTE: from UploadHelper#upload_submit_button
    opt[:config] ||= ENTRY_ACTION_VALUES
    form_submit_button(**opt)
  end

  # Entry cancel button.
  #
  # @param [Hash] opt                 Passed to #button_tag except for:
  #
  # @option opt [String, Symbol] :action    Default: `params[:action]`.
  # @option opt [String]         :label     Default: based on :action.
  # @option opt [String]         :url       Default: `params[:cancel]` or
  #                                           `request.referer`.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/download.js *cancelButton()*
  #
  def entry_cancel_button(**opt)                                                # NOTE: from UploadHelper#upload_cancel_button
    url = opt.delete(:url)
    opt[:'data-path'] ||= url || params[:cancel]
    opt[:'data-path'] ||= (request.referer if local_request? && !same_request?)
    opt[:model]       ||= :entry
    opt[:config]      ||= ENTRY_ACTION_VALUES
    form_cancel_button(**opt)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Element for displaying the name of the file that was uploaded.
  #
  # @param [String] leader            Text preceding the filename.
  # @param [Hash]   opt               Passed to #html_div for outer <div>.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def uploaded_filename_display(leader: nil, **opt)                             # NOTE: from UploadHelper
    css_selector = '.uploaded-filename'
    leader ||= 'Selected file:' # TODO: I18n
    html_div(prepend_classes!(opt, css_selector)) do
      html_span(leader, class: 'leader') << html_span('', class: 'filename')
    end
  end

  # Element name for field group radio buttons.                                 # NOTE: from UploadHelper::UPLOAD_FIELD_GROUP_NAME
  #
  # @type [String]
  #
  ENTRY_FIELD_GROUP_NAME = 'field-group'

  # Field group radio buttons and their labels and tooltips.                    # NOTE: from UploadHelper::UPLOAD_FIELD_GROUP
  #
  # @type [Hash{Symbol=>Hash{Symbol=>String}}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  ENTRY_FIELD_GROUP =
    I18n.t('emma.entry.field_group').deep_symbolize_keys.deep_freeze

  # Control for filtering which fields are displayed.
  #
  # @param [Hash] opt                 Passed to #html_div for outer <div>.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #ENTRY_FIELD_GROUP
  # @see file:app/assets/javascripts/feature/entry-form.js *fieldDisplayFilterSelect()*
  #
  def entry_field_group(**opt)                                                  # NOTE: from UploadHelper#upload_field_group
    css_selector = '.entry-field-group'

    # A label for the group (screen-reader only).
    legend = 'Filter input fields by state:' # TODO: I18n
    legend = html_tag(:legend, legend, class: 'sr-only')

    # Radio button controls.
    name = ENTRY_FIELD_GROUP_NAME
    controls =
      ENTRY_FIELD_GROUP.map do |group, properties|
        enabled = properties[:enabled].to_s
        next if false?(enabled)
        next if (enabled == 'debug') && !session_debug?

        tooltip  = properties[:tooltip]
        selected = true?(properties[:default])

        input = radio_button_tag(name, group, selected, role: 'radio')

        label = properties[:label] || group.to_s
        label = label_tag("#{name}_#{group}", label)

        html_div(class: 'radio', title: tooltip) { input << label }
      end

    prepend_classes!(opt, css_selector)
    opt[:role] = 'radiogroup'
    html_tag(:fieldset, legend, *controls, opt)
  end

  # Element for prompting for the EMMA index entry of the member repository
  # item which was the basis for the remediated item which is being submitted.
  #
  # @param [Hash] opt                 Passed to #html_div for outer <div>.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/entry-form.js *monitorSourceRepository()*
  #
  def parent_entry_select(**opt)                                                # NOTE: from UploadHelper#upload_parent_entry_select
    css_selector = '.parent-entry-select'
    id     = 'parent-entry-search'
    target = :search
    b_opt  = { role: 'button', tabindex: 0 }

    # Directions.
    t_id   = opt[:'aria-labelledby'] = "#{id}-title"
    title  =
      'Please indicate the EMMA entry for the original repository item. ' \
      'If possible, enter the standard identifier (ISBN, ISSN, OCLC, etc.) ' \
      'or the full title of the original work.' # TODO: I18n
    title  = html_div(title, id: t_id, class: 'search-title')

    # Text input.
    input  = search_input(id, target)

    # Submit button.
    submit = search_button_label(target)
    submit = html_div(submit, b_opt.merge(class: 'search-button'))

    # Cancel button.
    cancel = 'Cancel' # TODO: I18n
    cancel = html_div(cancel, b_opt.merge(class: 'search-cancel'))

    html_div(prepend_classes!(opt, css_selector, 'hidden')) do
      title << input << submit << cancel
    end
  end

  # Form fields are wrapped in an element for easier grid manipulation.
  #
  # @param [Entry] item
  # @param [Hash]  opt                Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def entry_field_container(item, **opt)                                        # NOTE: from UploadHelper#upload_field_container
    css_selector = '.entry-fields'
    html_div(prepend_classes!(opt, css_selector)) do
      entry_form_fields(item) << entry_no_fields_row
    end
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # Text for #entry_no_fields_row. # TODO: I18n                                 # NOTE: from UploadHelper::UPLOAD_NO_FIELDS
  #
  # @type [String]
  #
  ENTRY_NO_FIELDS = 'NO FIELDS'

  # Hidden row that is shown only when no field rows are being displayed.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def entry_no_fields_row                                                       # NOTE: from UploadHelper#upload_no_fields_row
    html_div(ENTRY_NO_FIELDS, class: 'no-fields')
  end

  # ===========================================================================
  # :section: Item forms (edit/delete pages)
  # ===========================================================================

  public

  # Generate a menu of existing EMMA entries.
  #
  # @param [Symbol, String] action    Default: `params[:action]`
  # @param [User, String]   user      Default: `@user`
  # @param [String]         prompt
  # @param [Hash]           opt       Passed to #page_items_menu.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def entries_menu(action: nil, user: nil, prompt: nil, **opt)                  # NOTE: from UploadHelper#upload_items_menu
    opt[:action] = action if action
    opt[:user]   = user || @user
    opt[:prompt] = prompt if prompt
    opt[:model]  = Entry
    opt[:controller] ||= :entry
    opt[:prompt] ||=
      if user
        'Select an EMMA entry you created' # TODO: I18n
      else
        'Select an existing EMMA entry' # TODO: I18n
      end
    page_items_menu(**opt)
  end

  # ===========================================================================
  # :section: Item forms (delete pages)
  # ===========================================================================

  public

  # Labels for inputs associated with transmitted parameters. # TODO: I18n      # NOTE: from UploadHelper::UPLOAD_DELETE_LABEL
  #
  # @type [Hash{Symbol=>String}]
  #
  ENTRY_DELETE_LABEL = {
    emergency:  'Attempt to remove index entries for bogus non-EMMA items?',
    force:      'Try to remove index entries of items not in the database?',
    truncate:   'Reset "entries" id field to 1?' \
                ' (Applies only when all records are being removed.)',
  }.freeze

  ENTRY_DELETE_OPTIONS        = ENTRY_DELETE_LABEL.keys.freeze                  # NOTE: from UploadHelper::UPLOAD_DELETE_OPTIONS
  ENTRY_DELETE_FORM_OPTIONS   = [:cancel, *ENTRY_DELETE_OPTIONS].freeze         # NOTE: from UploadHelper::UPLOAD_DELETE_FORM_OPTIONS
  ENTRY_DELETE_SUBMIT_OPTIONS = ENTRY_DELETE_OPTIONS                            # NOTE: from UploadHelper::UPLOAD_DELETE_SUBMIT_OPTIONS

  # Generate a form with controls for deleting a file and its entry.
  #
  # @param [Array<String,Entry>] items
  # @param [String]              label    Label for the submit button.
  # @param [Hash]                opt      Passed to 'entry-delete-form' except
  #                                         for:
  #
  # @option opt [String]  :cancel         Cancel button redirect URL passed to
  #                                         #entry_delete_cancel.
  # @option opt [Boolean] :force          Passed to #entry_delete_submit
  # @option opt [Boolean] :truncate       Passed to #entry_delete_submit
  # @option opt [Boolean] :emergency      Passed to #entry_delete_submit
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def entry_delete_form(*items, label: nil, **opt)                              # NOTE: from UploadHelper#upload_delete_form
    css_selector  = '.entry-delete-form'
    opt, html_opt = partition_hash(opt, *ENTRY_DELETE_FORM_OPTIONS)
    cancel = entry_delete_cancel(url: opt.delete(:cancel))
    submit = entry_delete_submit(*items, **opt.merge!(label: label))
    html_div(class: 'entry-form-container delete') do
      html_div(prepend_classes!(html_opt, css_selector)) do
        submit << cancel
      end
    end
  end

  # Submit button for the delete entry form.
  #
  # @param [Array<String,Entry>] items
  # @param [Hash]                opt      Passed to #delete_submit_button
  #                                         except for:
  #
  # @option opt [String, Symbol] :action      Default: `params[:action]`.
  #
  # @option opt [Boolean]        :force       If *true*, add 'force=true'
  #                                             to the form submission URL.
  # @option opt [Boolean]        :truncate    If *true*, add 'truncate=true'
  #                                             to the form submission URL.
  # @option opt [Boolean]        :emergency   If *true*, add 'emergency=true'
  #                                             to the form submission URL.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def entry_delete_submit(*items, **opt)                                        # NOTE: from UploadHelper#upload_delete_submit
    p_opt, opt = partition_hash(opt, *ENTRY_DELETE_SUBMIT_OPTIONS)
    ids = Entry.compact_ids(*items).join(',')
    url =
      if ids.present?
        p_opt[:id]        = ids
        p_opt[:force]     = force_delete     unless p_opt.key?(:force)
        p_opt[:truncate]  = truncate_delete  unless p_opt.key?(:truncate)
        p_opt[:emergency] = emergency_delete unless p_opt.key?(:emergency)
        destroy_entry_path(**p_opt)
      end
    delete_submit_button(config: ENTRY_ACTION_VALUES, url: url, **opt)
  end

  # Cancel button for the delete entry form.
  #
  # @param [Hash] opt                 Passed to #entry_cancel_button
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/download.js *cancelAction()*
  #
  def entry_delete_cancel(**opt)                                                # NOTE: from UploadHelper#upload_delete_cancel
    opt[:action]  ||= :delete
    opt[:onclick] ||= 'cancelAction();'
    entry_cancel_button(**opt)
  end

  # ===========================================================================
  # :section: Bulk new/edit/delete pages
  # ===========================================================================

  public

  # Initially hidden container used by the client to display intermediate
  # results during a bulk operation.
  #
  # @param [Hash] opt                 Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_entry_results(**opt)                                                 # NOTE: from UploadHelper#bulk_upload_results
    css_selector = '.bulk-op-results'

    l_sel = "#{css_selector}-label"
    l_id  = unique_id(l_sel)
    label = 'Previous upload results:' # TODO: I18n
    label = html_div(label, id: l_id, class: css_classes(l_sel, 'hidden'))

    prepend_classes!(opt, css_selector)
    append_classes!(opt, 'hidden')
    opt[:'aria-labelledby'] = l_id
    panel = html_div(opt)

    # noinspection RubyMismatchedReturnType
    label << panel
  end

  # ===========================================================================
  # :section: Bulk new/edit/delete pages
  # ===========================================================================

  protected

  # An option checkbox for a bulk action form.
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           param
  # @param [*]                                value
  # @param [Hash{Symbol=>String}]             labels
  # @param [Boolean]                          debug_only
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_option(f, param, value = nil, labels:, debug_only: false, **)        # NOTE: from UploadHelper
    if debug_only && !session_debug?
      hidden_input(param, value)
    else
      label = f.label(param, labels[param])
      check = f.check_box(param, checked: value)
      html_div(class: 'line') { check << label }
    end
  end

  # An input element for a bulk action form.
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           param
  # @param [*]                                value
  # @param [Symbol]                           meth
  # @param [Hash{Symbol=>String}]             labels
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_input(f, param, value = nil, meth: :text_field, labels:, **opt)      # NOTE: from UploadHelper
    label = f.label(param, labels[param])
    input = f.send(meth, param, value: value, **opt)
    html_div(class: 'line') { label << input }
  end

  # ===========================================================================
  # :section: Bulk new/edit pages
  # ===========================================================================

  public

  # Labels for inputs associated with transmitted parameters. # TODO: I18n      # NOTE: from UploadHelper::BULK_UPLOAD_LABEL
  #
  # @type [Hash{Symbol=>String}]
  #
  BULK_ENTRY_LABEL = {
    prefix: 'Title prefix:',
    batch:  'Batch size:'
  }.freeze

  BULK_ENTRY_OPTIONS      = BULK_ENTRY_LABEL.keys.freeze                        # NOTE: from UploadHelper::BULK_UPLOAD_OPTIONS
  BULK_ENTRY_FORM_OPTIONS = [:cancel, *BULK_ENTRY_OPTIONS].freeze               # NOTE: from UploadHelper::BULK_UPLOAD_FORM_OPTIONS

  # Generate a form with controls for uploading a file, entering metadata, and
  # submitting.
  #
  # @param [String]         label     Label for the submit button.
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [Hash]           opt       Passed to #form_with except for:
  #
  # @option opt [String]  :prefix     String to prepend to each title.
  # @option opt [Integer] :batch      Size of upload batches.
  # @option opt [String]  :cancel     URL for cancel button action.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_entry_form(label: nil, action: nil, **opt)                           # NOTE: from UploadHelper#bulk_upload_form
    css_selector = '.bulk-entry-form'
    action = (action || params[:action])&.to_sym
    opt, form_opt = partition_hash(opt, *BULK_ENTRY_FORM_OPTIONS)
    opt[:prefix] ||= title_prefix
    opt[:batch]  ||= batch_size

    # noinspection RubyCaseWithoutElseBlockInspection
    case action
      when :new
        form_opt[:url]      = bulk_create_entry_path
        form_opt[:method] ||= :post
      when :edit
        form_opt[:url]      = bulk_update_entry_path
        form_opt[:method] ||= :put
    end
    form_opt[:multipart]    = true
    form_opt[:autocomplete] = 'off'

    html_div(class: "entry-form-container bulk #{action}") do
      # @type [ActionView::Helpers::FormBuilder] f
      form_with(**prepend_classes!(form_opt, css_selector, action)) do |f|
        lines = []

        # === Batch title prefix input
        url_param = :prefix
        initial   = opt[url_param].presence
        if session_debug?
          lines << bulk_entry_input(f, url_param, initial)
        elsif initial
          lines << hidden_input(url_param, initial)
        end

        # === Batch size control
        url_param = :batch
        initial   = opt[url_param].presence
        field_opt = { meth: :number_field, min: 0 }
        lines << bulk_entry_input(f, url_param, initial, **field_opt)

        # === Form control panel
        lines <<
          html_div(class: 'form-controls') do
            controls_opt = { class: 'bulk' }
            button_opt   = controls_opt.merge(action: action)
            submit  = entry_submit_button(label: label,        **button_opt)
            cancel  = entry_cancel_button(url:   opt[:cancel], **button_opt)
            input   = bulk_entry_file_select(f, :source, **controls_opt)
            display = uploaded_filename_display(**controls_opt)
            prepend_classes!(controls_opt, 'button-tray')
            html_div(controls_opt) { submit << cancel << input << display }
          end

        safe_join(lines, "\n")
      end
    end
  end

  # ===========================================================================
  # :section: Bulk new/edit pages
  # ===========================================================================

  protected

  # An option checkbox for a bulk new/edit form.
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           param
  # @param [*]                                value
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #bulk_option
  #
  def bulk_entry_option(f, param, value = nil, **opt)                           # NOTE: from UploadHelper#bulk_upload_option
    opt[:labels] ||= BULK_ENTRY_LABEL
    bulk_option(f, param, value, **opt)
  end

  # An input element for a bulk new/edit form.
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           param
  # @param [*]                                value
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #bulk_input
  #
  def bulk_entry_input(f, param, value = nil, **opt)                            # NOTE: from UploadHelper#bulk_upload_input
    opt[:labels] ||= BULK_ENTRY_LABEL
    bulk_input(f, param, value, **opt)
  end

  # bulk_entry_file_select
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           meth
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see ActionView::Helpers::FormBuilder#label
  # @see ActionView::Helpers::FormBuilder#file_field
  #
  def bulk_entry_file_select(f, meth, **opt)                                    # NOTE: from UploadHelper#bulk_upload_file_select
    l_opt = { class: 'file-select', role: 'button', tabindex: 0 }
    l_opt = merge_html_options(opt, l_opt)
    label = f.label(meth, 'Select', l_opt) # TODO: I18n

    i_opt = { class: 'control-button', tabindex: -1 }
    i_opt = merge_html_options(opt, i_opt)
    input = f.file_field(meth, i_opt)

    html_div(class: 'uppy-FileInput-container bulk') do
      label << input
    end
  end

  # ===========================================================================
  # :section: Bulk delete page
  # ===========================================================================

  public

  BULK_ENTRY_DELETE_LABEL =                                                     # NOTE: from UploadHelper::BULK_DELETE_LABEL
    ENTRY_DELETE_LABEL.merge(selected: 'Items to delete:').freeze

  BULK_ENTRY_DELETE_OPTIONS      = ENTRY_DELETE_OPTIONS                         # NOTE: from UploadHelper::BULK_DELETE_OPTIONS
  BULK_ENTRY_DELETE_FORM_OPTIONS = ENTRY_DELETE_FORM_OPTIONS                    # NOTE: from UploadHelper::BULK_DELETE_FORM_OPTIONS

  # Generate a form with controls for getting a list of identifiers to pass on
  # to the "/entry/delete" page.
  #
  # @param [String,Array<String>,nil] ids
  # @param [String] label                 Label for the submit button.
  # @param [Hash]   opt                   Passed to #form_with except for:
  #
  # @option opt [Boolean] :force          Force index delete option
  # @option opt [Boolean] :truncate       Reset database ID option
  # @option opt [Boolean] :emergency      Emergency force delete option
  # @option opt [String]  :cancel         URL for cancel button action.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_entry_delete_form(label: nil, ids: nil, **opt)                       # NOTE: from UploadHelper#bulk_delete_form
    css_selector  = '.bulk-entry-form.delete'
    action        = :bulk_delete
    ids           = Array.wrap(ids).compact.presence
    opt, form_opt = partition_hash(opt, *BULK_ENTRY_DELETE_FORM_OPTIONS)

    opt[:force]     = force_delete     unless opt.key?(:force)
    opt[:truncate]  = truncate_delete  unless opt.key?(:truncate)
    opt[:emergency] = emergency_delete unless opt.key?(:emergency)

    form_opt[:url]          = delete_select_entry_path
    form_opt[:method]     ||= :get
    form_opt[:autocomplete] = 'off'
    form_opt[:local]        = true # Turns off "data-remote='true'".

    html_div(class: 'entry-form-container bulk delete') do
      # @type [ActionView::Helpers::FormBuilder] f
      form_with(**prepend_classes!(form_opt, css_selector)) do |f|
        lines = []

        # === Options
        dbg = { debug_only: true }
        { force: {}, truncate: dbg, emergency: dbg }.each_pair do |prm, opts|
          lines << bulk_entry_delete_option(f, prm, opt[prm], **opts)
        end

        # === Item selection input
        lines << bulk_entry_delete_input(f, :selected, ids)

        # === Form control panel
        lines <<
          html_div(class: 'form-controls') do
            html_div(class: 'button-tray') do
              tray = []
              tray << entry_submit_button(action: action, label: label)
              tray << entry_cancel_button(action: action, url: opt[:cancel])
              safe_join(tray)
            end
          end

        safe_join(lines, "\n")
      end
    end
  end

  # find_in_index
  #
  # @param [Array<String,Entry>] items
  #
  # @return [Array<(Array<Search::Record::MetadataRecord>,Array)>]
  #
  def find_in_index(*items, **)                                                 # NOTE: from UploadHelper
    found = failed = []
    items = items.flatten.compact
    if items.present?
      result = IngestService.instance.get_records(*items)
      found  = result.records
      sids   = found.map(&:emma_repositoryRecordId)
      failed = items.reject { |item| sids.include?(Entry.sid_value(item)) }
    end
    return found, failed
  end

  # ===========================================================================
  # :section: Bulk delete page
  # ===========================================================================

  protected

  # An option checkbox for a bulk delete form.
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           param
  # @param [*]                                value
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #bulk_option
  #
  def bulk_entry_delete_option(f, param, value = nil, **opt)                    # NOTE: from UploadHelper#bulk_delete_option
    opt[:labels] ||= BULK_ENTRY_DELETE_LABEL
    bulk_option(f, param, value, **opt)
  end

  # An input element for a bulk delete form.
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           param
  # @param [*]                                value
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #bulk_input
  #
  def bulk_entry_delete_input(f, param, value = nil, **opt)                     # NOTE: from UploadHelper#bulk_delete_input
    opt[:labels] ||= BULK_ENTRY_DELETE_LABEL
    bulk_input(f, param, value, **opt)
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
