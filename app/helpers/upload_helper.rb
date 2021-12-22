# app/helpers/upload_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the display and creation of Upload records,
# including support for file upload via Uppy.
#
module UploadHelper

  include Emma::Json
  include Emma::Unicode

  include ConfigurationHelper
  include I18nHelper
  include LinkHelper
  include ModelHelper
  include PopupHelper

  include UploadWorkflow::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Paths used by entry-form.js.                                                # NOTE: to EntryHelper::ENTRY_PATH
  #
  # @type [Hash]
  #
  UPLOAD_PATH = {
    index:    (UPLOAD_URL = '/upload'), # GET /upload                           # NOTE: to EntryHelper::ENTRY_URL
    new:      "#{UPLOAD_URL}/new",      # GET /upload/new
    edit:     "#{UPLOAD_URL}/edit",     # GET /upload/edit
    create:   UPLOAD_URL,               # POST /upload
    renew:    "#{UPLOAD_URL}/renew",    # POST /upload/renew
    reedit:   "#{UPLOAD_URL}/reedit",   # POST /upload/reedit
    cancel:   "#{UPLOAD_URL}/cancel",   # POST /upload/cancel
    endpoint: "#{UPLOAD_URL}/endpoint"  # POST /upload/endpoint
  }.deep_freeze

  # CSS styles.                                                                 # NOTE: to EntryHelper::ENTRY_STYLE
  #
  # @type [Hash]
  #
  UPLOAD_STYLE = {
    drag_target: 'upload-drag_and_drop',
    preview:     'upload-preview',
  }.deep_freeze

  # Display preview of Shrine uploads.  NOTE: Not currently enabled.            # NOTE: to EntryHelper::ENTRY_PREVIEW_ENABLED
  #
  # @type [Boolean]
  #
  UPLOAD_PREVIEW_ENABLED = false

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether preview is enabled.
  #
  # == Usage Notes
  # Uppy preview is only for image files.
  #
  def preview_enabled?                                                          # NOTE: to EntryHelper
    UPLOAD_PREVIEW_ENABLED
  end

  # Supply an element to contain a preview thumbnail of an image file.
  #
  # @param [Boolean] force
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If preview is not enabled.
  #
  def upload_preview(force = false)                                             # NOTE: to EntryHelper#entry_preview
    return unless force || preview_enabled?
    html_div('', class: UPLOAD_STYLE[:preview])
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default link tooltip.                                                       # NOTE: to EntryHelper::ENTRY_SHOW_TOOLTIP
  #
  # @type [String]
  #
  UPLOAD_SHOW_TOOLTIP = I18n.t('emma.upload.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Upload] item
  # @param [Hash]   opt               Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_link(item, **opt)                                                  # NOTE: to EntryHelper
    opt[:path]    = show_upload_path(id: item.id)
    opt[:tooltip] = UPLOAD_SHOW_TOOLTIP
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
  def render_file_data(item, **opt)                                             # NOTE: to EntryHelper
    data = item.try(:file_data) || item.try(:[], :file_data) or return
    render_json_data(item, data, **opt)
  end

  # Render the contents of the :emma_data field in the same order of EMMA data
  # fields as defined for search results.
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
  def render_emma_data(item, **opt)                                             # NOTE: to EntryHelper
    data  = item.try(:emma_data) || item.try(:[], :emma_data) or return
    pairs = json_parse(data)
    pairs &&=
      Model::SEARCH_RECORD_FIELDS.map { |field, config|
        value = pairs.delete(config[:label]) || pairs.delete(field)
        [field, value] unless value.nil?
      }.compact.to_h.merge(pairs)
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
  def render_json_data(item, value, **opt)                                      # NOTE: to EntryHelper
    return unless item
    opt[:model]     ||= item && Model.for(item) || :upload
    opt[:no_format] ||= :dc_description

    pairs = json_parse(value).presence
    pairs&.transform_values! do |v|
      v.is_a?(Hash) ? render_json_data(item, v, **opt) : v
    end
    pairs &&= render_field_values(item, pairs: pairs, **opt)
    pairs ||= render_empty_value(EMPTY_VALUE)

    # noinspection RubyMismatchedArgumentType
    html_div(pairs, class: 'data-list')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Upload, Model, Hash] item
  # @param [Any]                 value
  # @param [Hash]                opt    Passed to the render method.
  #
  # @return [Field::Type]
  # @return [String]
  # @return [nil]
  #
  # @see ModelHelper::List#render_value
  #
  def upload_render_value(item, value, **opt)                                   # NOTE: to EntryHelper#entry_render_value
    if value.is_a?(Symbol)
      if item.is_a?(Upload) && item.include?(value)
        case value
          when :file_data then render_file_data(item, **opt)
          when :emma_data then render_emma_data(item, **opt)
          else                 item[value] || EMPTY_VALUE
        end
      else
        # noinspection RubyMismatchedArgumentType
        Field.for(item, value)
      end
    end || render_value(item, value, **opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render upload attributes.                                                   # NOTE: to EntryHelper#entry_details
  #
  # @param [Upload]    item
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #model_details.
  #
  def upload_details(item, pairs: nil, **opt)
    opt[:model] = model = item && Model.for(item) || :upload
    opt[:pairs] = Model.show_fields(model).merge(pairs || {})
    model_details(item, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Groupings of states related by theme.                                       # NOTE: to EntryHelper::ENTRY_STATE_GROUP
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/controllers/upload.en.yml *en.emma.upload.state_group*
  #
  UPLOAD_STATE_GROUP =
    Upload::WorkflowMethods::STATE_GROUP.transform_values do |entry|
      entry.map { |key, value|
        if %i[enabled show].include?(key)
          if value.nil? || true?(value)
            value = true
          elsif false?(value)
            value = false
          elsif value == 'nonzero'
            value =
              ->(list, group = nil) {
                list &&= list.select { |r| r.state_group == group } if group
                list.present?
              }
          end
        end
        [key, value]
      }.to_h
    end

  # CSS class for the upload state selection panel.                             # NOTE: to EntryHelper::ENTRY_GROUP_PANEL_CLASS
  #
  # @type [String]
  #
  UPLOAD_GROUP_PANEL_CLASS = 'upload-select-group-panel'

  # CSS class for the state group controls container.                           # NOTE: to EntryHelper::ENTRY_GROUP_CLASS
  #
  # @type [String]
  #
  UPLOAD_GROUP_CLASS = 'upload-select-group'

  # CSS class for a control within the upload state selection panel.            # NOTE: to EntryHelper::ENTRY_GROUP_CONTROL_CLASS
  #
  # @type [String]
  #
  UPLOAD_GROUP_CONTROL_CLASS = 'control'

  # Select Upload records based on workflow state group.
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
  # @see #UPLOAD_STATE_GROUP
  # @see file:app/assets/javascripts/feature/records.js *filterPageDisplay()*
  #
  # == Usage Notes
  # This is invoked from ModelHelper::List#page_filter.
  #
  def upload_state_group_select(counts: nil, **opt)                             # NOTE: to EntryHelper#entry_state_group_select
    css_selector = UPLOAD_GROUP_PANEL_CLASS
    curr_path  = opt.delete(:curr_path)  || request.fullpath
    curr_group = opt.delete(:curr_group) || request_parameters[:group] || :all
    curr_group = curr_group.to_sym if curr_group.is_a?(String)
    counts   ||= @group_counts || {}

    # A label preceding the group of buttons (screen-reader only).
    p_id   = "label-#{UPLOAD_GROUP_CLASS}"
    prefix = 'Select records based on their submission state:' # TODO: I18n
    prefix = html_div(prefix, id: p_id, class: 'sr-only')

    # Create buttons for each state group that has entries.
    buttons =
      UPLOAD_STATE_GROUP.map do |group, properties|
        all     = (group == :all)
        count   = counts[group] || 0
        enabled = all || count.positive?
        next unless enabled || session_debug?

        label = properties[:label] || group
        label = html_span(label, class: 'label')
        label << html_span("(#{count})", class: 'count')

        base  = upload_index_path
        url   = all ? base : upload_index_path(group: group)

        link_opt = {
          class:        UPLOAD_GROUP_CONTROL_CLASS,
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
    prepend_classes!(opt, UPLOAD_GROUP_CLASS)
    opt[:role]              = 'navigation'
    opt[:'aria-labelledby'] = p_id
    group = html_div(*buttons, opt)

    # An element following the group to hold a dynamic description of the group
    # button currently hovered/focused.  (@see javascripts/feature/records.js)
    note = html_div(HTML_SPACE, class: 'note', 'aria-hidden': true)
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

  # Control whether in-page filtering is allowed.                               # NOTE: to EntryHelper::ENTRY_PAGE_FILTERING
  #
  # @type [Boolean]
  #
  UPLOAD_PAGE_FILTERING = false

  # CSS class for the state group page filter panel.                            # NOTE: to EntryHelper::ENTRY_PAGE_FILTER_CLASS
  #
  # @type [String]
  #
  UPLOAD_PAGE_FILTER_CLASS = 'upload-page-filter-panel'

  # CSS class for the state group controls container.                           # NOTE: to EntryHelper::ENTRY_FILTER_GROUP_CLASS
  #
  # @type [String]
  #
  UPLOAD_FILTER_GROUP_CLASS = 'upload-filter-group'

  # CSS class for a control within the state group controls container.          # NOTE: to EntryHelper::ENTRY_FILTER_CONTROL_CLASS
  #
  # @type [String]
  #
  UPLOAD_FILTER_CONTROL_CLASS = 'control'

  # Control for filtering which records are displayed.
  #
  # @param [Array<Upload>] list       Default: `#page_items`.
  # @param [Hash]          counts     A table of group names associated with
  #                                     their overall totals (default:
  #                                     @group_counts).
  # @param [Hash]          opt        Passed to inner #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If #UPLOAD_PAGE_FILTERING is *false*.
  #
  # @see #UPLOAD_STATE_GROUP
  # @see file:app/assets/javascripts/feature/records.js *filterPageDisplay()*
  #
  # == Usage Notes
  # This is invoked from ModelHelper::List#page_filter.
  #
  def upload_page_filter(*list, counts: nil, **opt)                             # NOTE: to EntryHelper#entry_page_filter
    return unless UPLOAD_PAGE_FILTERING
    css_selector = UPLOAD_PAGE_FILTER_CLASS
    name     = __method__.to_s
    counts ||= @group_counts || {}
    list     = page_items if list.blank?
    table    = list.group_by(&:state_group)

    # Create radio button controls for each state group that has entries.
    controls =
      UPLOAD_STATE_GROUP.map do |group, properties|
        items   = table[group]  || []
        all     = (group == :all)
        count   = counts[group] || (all ? list.size : items.size)
        enabled = all || count.positive?
        # noinspection RubyMismatchedArgumentType
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
          class:        UPLOAD_FILTER_CONTROL_CLASS,
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
    prepend_classes!(opt, UPLOAD_FILTER_GROUP_CLASS)
    opt[:role] = 'radiogroup'
    group = html_div(controls, opt)

    # A label for the group (screen-reader only).
    legend = 'Choose the upload submission state to display:' # TODO: I18n
    legend = html_tag(:legend, legend, class: 'sr-only')

    # Include the group in a panel with accompanying label.
    outer_opt = { class: css_classes(css_selector) }
    append_classes!(outer_opt, 'hidden') if controls.size <= 1
    field_set_tag(nil, outer_opt) do
      legend << group
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # CSS class for the debug-only panel of checkboxes to control filter          # NOTE: to EntryHelper::ENTRY_FILTER_OPTIONS_CLASS
  # visibility.
  #
  # @type [String]
  #
  UPLOAD_FILTER_OPTIONS_CLASS = 'upload-filter-options-panel'

  # Control the selection of filters displayed by #upload_page_filter.
  #
  # @param [Array<Upload>] list       Default: `#page_items`.
  # @param [Hash]          opt        Passed to #html_div for outer <div>.
  #
  # @option opt [Array] :records      List of upload records for display.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/records.js *filterOptionToggle()*
  #
  def upload_page_filter_options(*list, **opt)                                  # NOTE: to EntryHelper#entry_page_filter_options
    css_selector = UPLOAD_FILTER_OPTIONS_CLASS
    name     = __method__.to_s
    counts ||= @group_counts || {}
    list     = page_items if list.blank? && counts.blank?

    # A label preceding the group (screen-reader only).
    legend = 'Select/de-select state groups to show' # TODO: I18n
    legend = html_tag(:legend, legend, class: 'sr-only')

    # Checkboxes.
    cb_opt = { class: UPLOAD_FILTER_CONTROL_CLASS }
    groups = { ALL_FILTERS: { label: 'Show all filters', checked: false } }
    groups.merge!(UPLOAD_STATE_GROUP)
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
  # @param [Symbol, nil]        group
  # @param [Hash, nil]          properties
  # @param [Array<Upload>, nil] list
  #
  def active_state_group?(group, properties, list)                              # NOTE: to EntryHelper
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

  # CSS class for the containing of a listing of Upload records.                # NOTE: to EntryHelper::ENTRY_LIST_CLASS
  #
  # @type [String]
  #
  UPLOAD_LIST_CLASS = 'upload-list'

  # Render a single entry for use within a list of items.                       # NOTE: to EntryHelper#entry_list_item
  #
  # @param [Upload]    item
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #model_list_item.
  #
  def upload_list_item(item, pairs: nil, **opt)
    opt[:model] = model = item && Model.for(item) || :upload
    opt[:pairs] = Model.index_fields(model).merge(pairs || {})
    model_list_item(item, **opt)
  end

  # Include control icons below the entry number.
  #
  # @param [Upload] item
  # @param [Hash]   opt               Passed to #list_item_number.
  #
  def upload_list_item_number(item, **opt)                                      # NOTE: to EntryHelper#entry_list_item_number
    list_item_number(item, **opt) do
      upload_entry_icons(item)
    end
  end

  # Text for #upload_no_records_row. # TODO: I18n                               # NOTE: to EntryHelper::ENTRY_NO_RECORDS
  #
  # @type [String]
  #
  UPLOAD_NO_RECORDS = 'NO RECORDS'

  # Hidden row that is shown only when no field rows are being displayed.
  #
  # @param [Hash] opt                 Passed to created elements.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_no_records_row(**opt)                                              # NOTE: to EntryHelper#entry_no_records_row
    css_selector = '.no-records'
    prepend_classes!(opt, css_selector)
    # noinspection RubyMismatchedReturnType
    html_div('', opt) << html_div(UPLOAD_NO_RECORDS, opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Upload action icon definitions.                                             # NOTE: to EntryHelper::ENTRY_CONTROL_ICONS
  #
  # @type [Hash{Symbol=>Hash{Symbol=>Any}}]
  #
  UPLOAD_ICONS = {
    check: {
      icon:    BANG,
      tip:     'Check for an update to the status of this submission', # TODO: I18n
      path:    :check_upload_path,
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
  # authorized to perform on the item.
  #
  # @param [Upload] item
  # @param [Hash]   opt                 Passed to #upload_action_icon
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       If no operations are authorized.
  #
  # @see #UPLOAD_ICONS
  #
  def upload_entry_icons(item, **opt)                                           # NOTE: to EntryHelper#entry_control_icons
    css_selector = '.icon-tray'
    icons =
      # @type [Symbol] operation
      # @type [Hash]   properties
      UPLOAD_ICONS.map { |operation, properties|
        next unless can?(operation, item)
        action_opt = properties.merge(opt)
        action_opt[:item] ||= (item if item.is_a?(Model))
        # noinspection RubyMismatchedReturnType
        upload_action_icon(operation, **action_opt)
      }.compact
    html_span(icons, class: css_classes(css_selector)) if icons.present?
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  protected

  # Produce an upload action icon based on either :path or :id.
  #
  # @param [Symbol] op                    One of #UPLOAD_ICONS.keys.
  # @param [Hash]   opt                   Passed to #make_link except for:
  #
  # @option opt [Upload]        :item
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
  def upload_action_icon(op, **opt)                                             # NOTE: to EntryHelper#entry_control_icon
    css_selector = '.icon'
    item         = opt.delete(:item)
    model        = :upload
    id           = opt.delete(:id) || item.try(:id)
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
    # noinspection RubyMismatchedArgumentType
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
  # @param [Upload]         item
  # @param [String, Symbol] path
  # @param [Hash]           opt         Passed to #popup_container except for:
  #
  # @option opt [Hash] :attr            Options for deferred content.
  # @option opt [Hash] :placeholder     Options for transient placeholder.
  #
  # @see file:app/assets/javascripts/feature/popup.js *togglePopup()*
  #
  def check_status_popup(item, path, **opt)                                     # NOTE: to EntryHelper
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

  # Render pre-populated form fields.                                           # NOTE: to EntryHelper#entry_form_fields
  #
  # @param [Upload]    item
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #render_form_fields.
  #
  def upload_form_fields(item, pairs: nil, **opt)
    opt[:model] = model = item && Model.for(item) || :upload
    opt[:pairs] = Model.form_fields(model).merge(pairs || {})
    render_form_fields(item, **opt)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Button information for upload actions.                                      # NOTE: to EntryHelper::ENTRY_ACTION_VALUES
  #
  # @type [Hash{Symbol=>Hash}]
  #
  UPLOAD_ACTION_VALUES =
    %i[new edit delete bulk_new bulk_edit bulk_delete].map { |action|
      [action, config_button_values(:upload, action)]
    }.to_h.deep_freeze

  # Screen-reader-only label for file input.  (This is to satisfy accessibility # NOTE: to EntryHelper
  # checkers which don't ignore the file input which is made invisible in favor
  # of the Uppy file input control).
  #
  # @type [String]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  FILE_LABEL = I18n.t('emma.upload.new.select.label').freeze

  # Generate a form with controls for uploading a file, entering metadata, and
  # submitting.
  #
  # @param [Upload]         item
  # @param [String]         label     Label for the submit button.
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [Hash]           opt       Passed to #form_with except for:
  #
  # @option opt [String] :cancel      URL for cancel button action (default:
  #                                     :back).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_form(item, label: nil, action: nil, **opt)                         # NOTE: to EntryHelper#entry_form
    css_selector = '.entry-form'
    action ||= params[:action]
    cancel   = opt.delete(:cancel)

    # noinspection RubyCaseWithoutElseBlockInspection
    case action
      when :new
        opt[:url]      = create_upload_path
      when :edit
        opt[:url]      = update_upload_path
        opt[:method] ||= :put
    end
    opt[:multipart]    = true
    opt[:autocomplete] = 'off'

    prepend_classes!(opt, css_selector, action)
    scroll_to_top_target!(opt)

    html_div(class: "entry-form-container #{action}") do
      # @type [ActionView::Helpers::FormBuilder] f
      form_with(model: item, **opt) do |f|
        data_opt = { class: 'upload-hidden' }

        # Extra information to support reverting the record when canceled.
        rev_data  = item&.get_revert_data&.to_json
        rev_data  = data_opt.merge!(id: 'revert_data', value: rev_data)
        rev_data  = f.hidden_field(:revert_data, rev_data)

        # Communicate :file_data through the form as a hidden field.
        file_data = item&.active_file_data || item&.file_data
        file_data = data_opt.merge!(id: 'upload_file_data', value: file_data)
        file_data = f.hidden_field(:file, file_data)

        # Hidden data fields.
        emma_data = item&.active_emma_data || item&.emma_data
        emma_data = data_opt.merge!(id: 'upload_emma_data', value: emma_data)
        emma_data = f.hidden_field(:emma_data, emma_data)

        # Control elements which are always visible at the top of the input
        # form.
        controls =
          html_div(class: 'controls') do
            # Button tray.
            tray = []
            tray << upload_submit_button(action: action, label: label)
            tray << upload_cancel_button(action: action, url: cancel)
            tray << f.label(:file, FILE_LABEL, class: 'sr-only', id: 'fi_label')
            tray << f.file_field(:file)
            tray << uploaded_filename_display
            tray = html_div(class: 'button-tray') { tray }

            # Field display selections.
            tabs = upload_field_group

            # Parent entry input control.
            parent_input = upload_parent_entry_select

            tray << tabs << parent_input
          end

        # Form fields.
        fields = upload_field_container(item)

        # Convenience submit and cancel buttons below the fields.
        bottom =
          html_div(class: 'controls') do
            tray = []
            tray << upload_submit_button(action: action, label: label)
            tray << upload_cancel_button(action: action, url: cancel)
            html_div(class: 'button-tray') { tray }
          end

        # All form sections.
        sections = [emma_data, file_data, rev_data, controls, fields, bottom]
        safe_join(sections, "\n")
      end
    end
  end

  # Upload submit button.
  #
  # @param [Hash] opt                 Passed to #form_submit_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/download.js *submitButton()*
  #
  def upload_submit_button(**opt)                                               # NOTE: to EntryHelper#entry_submit_button
    opt[:config] ||= UPLOAD_ACTION_VALUES
    form_submit_button(**opt)
  end

  # Upload cancel button.
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
  def upload_cancel_button(**opt)                                               # NOTE: to EntryHelper#entry_cancel_button
    url = opt.delete(:url)
    opt[:'data-path'] ||= url || params[:cancel]
    opt[:'data-path'] ||= (request.referer if local_request? && !same_request?)
    opt[:model]       ||= :upload
    opt[:config]      ||= UPLOAD_ACTION_VALUES
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
  def uploaded_filename_display(leader: nil, **opt)                             # NOTE: to EntryHelper
    css_selector = '.uploaded-filename'
    leader ||= 'Selected file:' # TODO: I18n
    html_div(prepend_classes!(opt, css_selector)) do
      html_span(leader, class: 'leader') << html_span('', class: 'filename')
    end
  end

  # Element name for field group radio buttons.                                 # NOTE: to EntryHelper::ENTRY_FIELD_GROUP_NAME
  #
  # @type [String]
  #
  UPLOAD_FIELD_GROUP_NAME = 'field-group'

  # Field group radio buttons and their labels and tooltips.                    # NOTE: to EntryHelper::ENTRY_FIELD_GROUP
  #
  # @type [Hash{Symbol=>Hash{Symbol=>String}}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  UPLOAD_FIELD_GROUP =
    I18n.t('emma.upload.field_group').deep_symbolize_keys.deep_freeze

  # Control for filtering which fields are displayed.
  #
  # @param [Hash] opt                 Passed to #html_div for outer <div>.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #UPLOAD_FIELD_GROUP
  # @see file:app/assets/javascripts/feature/entry-form.js *fieldDisplayFilterSelect()*
  #
  def upload_field_group(**opt)                                                 # NOTE: to EntryHelper#entry_field_group
    css_selector = '.upload-field-group'

    # A label for the group (screen-reader only).
    legend = 'Filter input fields by state:' # TODO: I18n
    legend = html_tag(:legend, legend, class: 'sr-only')

    # Radio button controls.
    name = UPLOAD_FIELD_GROUP_NAME
    controls =
      UPLOAD_FIELD_GROUP.map do |group, properties|
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
  def upload_parent_entry_select(**opt)                                         # NOTE: to EntryHelper#parent_entry_select
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
  # @param [Upload] item
  # @param [Hash]   opt               Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_field_container(item, **opt)                                       # NOTE: to EntryHelper#entry_field_container
    css_selector = '.upload-fields'
    html_div(prepend_classes!(opt, css_selector)) do
      upload_form_fields(item) << upload_no_fields_row
    end
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # Text for #upload_no_fields_row. # TODO: I18n                                # NOTE: to EntryHelper::ENTRY_NO_FIELDS
  #
  # @type [String]
  #
  UPLOAD_NO_FIELDS = 'NO FIELDS'

  # Hidden row that is shown only when no field rows are being displayed.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_no_fields_row                                                      # NOTE: to EntryHelper#entry_no_fields_row
    html_div(UPLOAD_NO_FIELDS, class: 'no-fields')
  end

  # ===========================================================================
  # :section: Item forms (edit/delete pages)
  # ===========================================================================

  public

  # Generate a menu of existing EMMA entries (uploaded items).
  #
  # @param [Symbol, String] action    Default: `params[:action]`
  # @param [User, String]   user      Default: `@user`
  # @param [String]         prompt
  # @param [Hash]           opt       Passed to #page_items_menu.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_items_menu(action: nil, user: nil, prompt: nil, **opt)             # NOTE: to EntryHelper#entries_menu
    opt[:action] = action if action
    opt[:user]   = user || @user
    opt[:prompt] = prompt if prompt
    opt[:model]  = Upload
    opt[:controller] ||= :upload
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

  # Labels for inputs associated with transmitted parameters. # TODO: I18n      # NOTE: to EntryHelper::ENTRY_DELETE_LABEL
  #
  # @type [Hash{Symbol=>String}]
  #
  UPLOAD_DELETE_LABEL = {
    emergency:  'Attempt to remove index entries for bogus non-EMMA items?',
    force:      'Try to remove index entries of items not in the database?',
    truncate:   'Reset "uploads" id field to 1?' \
                ' (Applies only when all records are being removed.)',
  }.freeze

  UPLOAD_DELETE_OPTIONS        = UPLOAD_DELETE_LABEL.keys.freeze                # NOTE: to EntryHelper::ENTRY_DELETE_OPTIONS
  UPLOAD_DELETE_FORM_OPTIONS   = [:cancel, *UPLOAD_DELETE_OPTIONS].freeze       # NOTE: to EntryHelper::ENTRY_DELETE_FORM_OPTIONS
  UPLOAD_DELETE_SUBMIT_OPTIONS = UPLOAD_DELETE_OPTIONS                          # NOTE: to EntryHelper::ENTRY_DELETE_SUBMIT_OPTIONS

  # Generate a form with controls for deleting a file and its entry.
  #
  # @param [Array<String,Upload>] items
  # @param [String]               label   Label for the submit button.
  # @param [Hash]                 opt     Passed to 'entry-delete-form' except
  #                                         for:
  #
  # @option opt [String]  :cancel         Cancel button redirect URL passed to
  #                                         #upload_delete_cancel.
  # @option opt [Boolean] :force          Passed to #upload_delete_submit
  # @option opt [Boolean] :truncate       Passed to #upload_delete_submit
  # @option opt [Boolean] :emergency      Passed to #upload_delete_submit
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_delete_form(*items, label: nil, **opt)                             # NOTE: to EntryHelper#entry_delete_form
    css_selector  = '.entry-delete-form'
    opt, html_opt = partition_hash(opt, *UPLOAD_DELETE_FORM_OPTIONS)
    cancel = upload_delete_cancel(url: opt.delete(:cancel))
    submit = upload_delete_submit(*items, **opt.merge!(label: label))
    html_div(class: 'entry-form-container delete') do
      html_div(prepend_classes!(html_opt, css_selector)) do
        submit << cancel
      end
    end
  end

  # Submit button for the delete upload form.
  #
  # @param [Array<String,Upload>] items
  # @param [Hash]                 opt     Passed to #delete_submit_button
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
  def upload_delete_submit(*items, **opt)                                       # NOTE: to EntryHelper#entry_delete_submit
    p_opt, opt = partition_hash(opt, *UPLOAD_DELETE_SUBMIT_OPTIONS)
    ids = Upload.compact_ids(*items).join(',')
    url =
      if ids.present?
        p_opt[:id]        = ids
        p_opt[:force]     = force_delete     unless p_opt.key?(:force)
        p_opt[:truncate]  = truncate_delete  unless p_opt.key?(:truncate)
        p_opt[:emergency] = emergency_delete unless p_opt.key?(:emergency)
        destroy_upload_path(**p_opt)
      end
    delete_submit_button(config: UPLOAD_ACTION_VALUES, url: url, **opt)
  end

  # Cancel button for the delete upload form.
  #
  # @param [Hash] opt                 Passed to #upload_cancel_button
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/download.js *cancelAction()*
  #
  def upload_delete_cancel(**opt)                                               # NOTE: to EntryHelper#entry_delete_cancel
    opt[:action]  ||= :delete
    opt[:onclick] ||= 'cancelAction();'
    upload_cancel_button(**opt)
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
  def bulk_upload_results(**opt)                                                # NOTE: to EntryHelper#bulk_entry_results
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
  # @param [Any, nil]                         value
  # @param [Hash{Symbol=>String}]             labels
  # @param [Boolean]                          debug_only
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_option(f, param, value = nil, labels:, debug_only: false, **)        # NOTE: to EntryHelper
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
  # @param [Any, nil]                         value
  # @param [Symbol]                           meth
  # @param [Hash{Symbol=>String}]             labels
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_input(f, param, value = nil, meth: :text_field, labels:, **opt)      # NOTE: to EntryHelper
    label = f.label(param, labels[param])
    input = f.send(meth, param, value: value, **opt)
    html_div(class: 'line') { label << input }
  end

  # ===========================================================================
  # :section: Bulk new/edit pages
  # ===========================================================================

  public

  # Labels for inputs associated with transmitted parameters. # TODO: I18n      # NOTE: to EntryHelper::BULK_ENTRY_LABEL
  #
  # @type [Hash{Symbol=>String}]
  #
  BULK_UPLOAD_LABEL = {
    prefix: 'Title prefix:',
    batch:  'Batch size:'
  }.freeze

  BULK_UPLOAD_OPTIONS      = BULK_UPLOAD_LABEL.keys.freeze                      # NOTE: to EntryHelper::BULK_ENTRY_OPTIONS
  BULK_UPLOAD_FORM_OPTIONS = [:cancel, *BULK_UPLOAD_OPTIONS].freeze             # NOTE: to EntryHelper::BULK_ENTRY_FORM_OPTIONS

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
  def bulk_upload_form(label: nil, action: nil, **opt)                          # NOTE: to EntryHelper#bulk_entry_form
    css_selector = '.bulk-entry-form'
    action = (action || params[:action])&.to_sym
    opt, form_opt = partition_hash(opt, *BULK_UPLOAD_FORM_OPTIONS)
    opt[:prefix] ||= title_prefix
    opt[:batch]  ||= batch_size

    # noinspection RubyCaseWithoutElseBlockInspection
    case action
      when :new
        form_opt[:url]      = bulk_create_upload_path
        form_opt[:method] ||= :post
      when :edit
        form_opt[:url]      = bulk_update_upload_path
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
          lines << bulk_upload_input(f, url_param, initial)
        elsif initial
          lines << hidden_input(url_param, initial)
        end

        # === Batch size control
        url_param = :batch
        initial   = opt[url_param].presence
        field_opt = { meth: :number_field, min: 0 }
        lines << bulk_upload_input(f, url_param, initial, **field_opt)

        # === Form control panel
        lines <<
          html_div(class: 'form-controls') do
            controls_opt = { class: 'bulk' }
            button_opt   = controls_opt.merge(action: action)
            submit  = upload_submit_button(label: label,        **button_opt)
            cancel  = upload_cancel_button(url:   opt[:cancel], **button_opt)
            input   = bulk_upload_file_select(f, :source, **controls_opt)
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
  # @param [Any, nil]                         value
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #bulk_option
  #
  def bulk_upload_option(f, param, value = nil, **opt)                          # NOTE: to EntryHelper#bulk_entry_option
    opt[:labels] ||= BULK_UPLOAD_LABEL
    bulk_option(f, param, value, **opt)
  end

  # An input element for a bulk new/edit form.
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           param
  # @param [Any, nil]                         value
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #bulk_input
  #
  def bulk_upload_input(f, param, value = nil, **opt)                           # NOTE: to EntryHelper#bulk_entry_input
    opt[:labels] ||= BULK_UPLOAD_LABEL
    bulk_input(f, param, value, **opt)
  end

  # bulk_upload_file_select
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
  def bulk_upload_file_select(f, meth, **opt)                                   # NOTE: to EntryHelper#bulk_entry_file_select
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

  BULK_DELETE_LABEL =                                                           # NOTE: to EntryHelper::BULK_ENTRY_DELETE_LABEL
    UPLOAD_DELETE_LABEL.merge(selected: 'Items to delete:').freeze

  BULK_DELETE_OPTIONS      = UPLOAD_DELETE_OPTIONS                              # NOTE: to EntryHelper::BULK_ENTRY_DELETE_OPTIONS
  BULK_DELETE_FORM_OPTIONS = UPLOAD_DELETE_FORM_OPTIONS                         # NOTE: to EntryHelper::BULK_ENTRY_DELETE_FORM_OPTIONS

  # Generate a form with controls for getting a list of identifiers to pass on
  # to the "/upload/delete" page.
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
  def bulk_delete_form(label: nil, ids: nil, **opt)                             # NOTE: to EntryHelper#bulk_entry_delete_form
    css_selector  = '.bulk-entry-form.delete'
    action        = :bulk_delete
    ids           = Array.wrap(ids).compact.presence
    opt, form_opt = partition_hash(opt, *BULK_DELETE_FORM_OPTIONS)

    opt[:force]     = force_delete     unless opt.key?(:force)
    opt[:truncate]  = truncate_delete  unless opt.key?(:truncate)
    opt[:emergency] = emergency_delete unless opt.key?(:emergency)

    form_opt[:url]          = delete_select_upload_path
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
          lines << bulk_delete_option(f, prm, opt[prm], **opts)
        end

        # === Item selection input
        lines << bulk_delete_input(f, :selected, ids)

        # === Form control panel
        lines <<
          html_div(class: 'form-controls') do
            html_div(class: 'button-tray') do
              tray = []
              tray << upload_submit_button(action: action, label: label)
              tray << upload_cancel_button(action: action, url: opt[:cancel])
              safe_join(tray)
            end
          end

        safe_join(lines, "\n")
      end
    end
  end

  # find_in_index
  #
  # @param [Array<Upload, String>] items
  #
  # @return [Array<(Array<Search::Record::MetadataRecord>,Array)>]
  #
  def find_in_index(*items, **)                                                 # NOTE: to EntryHelper
    found = failed = []
    items = items.flatten.compact
    if items.present?
      result = IngestService.instance.get_records(*items)
      found  = result.records
      sids   = found.map(&:emma_repositoryRecordId)
      failed =
        items.reject do |item|
          sid =
            if item.respond_to?(:submission_id)
              item.submission_id
            elsif item.is_a?(Hash)
              item[:submission_id] || item['submission_id']
            else
              item
            end
          sids.include?(sid)
        end
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
  # @param [Any, nil]                         value
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #bulk_option
  #
  def bulk_delete_option(f, param, value = nil, **opt)                          # NOTE: to EntryHelper#bulk_entry_delete_option
    opt[:labels] ||= BULK_DELETE_LABEL
    bulk_option(f, param, value, **opt)
  end

  # An input element for a bulk delete form.
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           param
  # @param [Any, nil]                         value
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #bulk_input
  #
  def bulk_delete_input(f, param, value = nil, **opt)                           # NOTE: to EntryHelper#bulk_entry_delete_input
    opt[:labels] ||= BULK_DELETE_LABEL
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
