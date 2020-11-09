# app/helpers/upload_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Upload configuration values for Uppy.
#
module UploadHelper

  def self.included(base)
    __included(base, '[UploadHelper]')
  end

  include Emma::Json
  include Emma::Unicode
  include I18nHelper
  include ModelHelper
  include UploadWorkflow::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values for this model.
  #
  # @type {Hash{Symbol=>Hash}}
  #
  UPLOAD_CONFIGURATION = Model.configuration('emma.upload').deep_freeze
  UPLOAD_INDEX_FIELDS  = UPLOAD_CONFIGURATION.dig(:index, :fields)
  UPLOAD_SHOW_FIELDS   = UPLOAD_CONFIGURATION.dig(:show,  :fields)

  # Mapping of label keys to fields from `Upload#attributes`.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  UPLOAD_DATABASE_FIELDS = UPLOAD_CONFIGURATION.dig(:fields, :database)

  # Reverse mapping of database field to the label configured for it.
  #
  # @type [Hash{Symbol=>String,Symbol}]
  #
  UPLOAD_DATABASE_LABELS = UPLOAD_DATABASE_FIELDS.invert.deep_freeze
=begin # TODO: use when configuration is transitioned...
  UPLOAD_DATABASE_LABELS = UPLOAD_DATABASE_FIELDS
=end

  # Mapping of label keys to fields from Search::Record::MetadataRecord.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  SEARCH_RECORD_FIELDS = UPLOAD_CONFIGURATION.dig(:fields, :form)

  # Reverse mapping of EMMA search record field to the label configured for it.
  #
  # @type [Hash{Symbol=>String,Symbol}]
  #
  SEARCH_RECORD_LABELS = SEARCH_RECORD_FIELDS.invert.deep_freeze
=begin # TODO: use when configuration is transitioned...
  SEARCH_RECORD_LABELS = SEARCH_RECORD_FIELDS
=end

  # Linkage information for upload actions.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  UPLOAD_ACTIONS = {
    new: {
      label: 'Upload %s new file',       article: 'a',  action: 'new'
    },
    edit: {
      label: 'Modify %s existing entry', article: 'an', action: 'edit_select'
    },
    delete: {
      label: 'Remove %s existing entry', article: 'an', action: 'delete_select'
    }
  }.deep_freeze

  # TODO: I18n
  #
  # @type [String]
  #
  UPLOAD_ANOTHER = 'another'

  # Paths used by file-upload.js.
  #
  # @type [Hash]
  #
  UPLOAD_PATH = {
    index:    (UPLOAD_URL = '/upload'), # GET /upload
    create:   UPLOAD_URL,               # POST /upload
    cancel:   "#{UPLOAD_URL}/cancel",   # POST /upload/cancel
    endpoint: "#{UPLOAD_URL}/endpoint"  # POST /upload/endpoint
  }.deep_freeze

  # CSS styles
  #
  # @type [Hash]
  #
  UPLOAD_STYLE = {
    drag_target: 'upload-drag_and_drop',
    preview:     'upload-preview',
  }.deep_freeze

  # Display preview of Shrine uploads.  NOTE: Not currently enabled.
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
  def preview_enabled?
    UPLOAD_PREVIEW_ENABLED
  end

  # Supply an element to contain a preview thumbnail of an image file.
  #
  # @param [Boolean] force
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If preview is not enabled.
  #
  def upload_preview(force = false)
    return unless force || preview_enabled?
    html_div('', class: UPLOAD_STYLE[:preview])
  end

  # upload_action_entry
  #
  # @param [String, Symbol, nil] action   The target action.
  # @param [String, Symbol, nil] current  The current `params[:action]`.
  #
  # @return [Hash{Symbol=>String}]
  #
  def upload_action_entry(action = nil, current: nil)
    current ||= params[:action]
    action  ||= current
    entry = UPLOAD_ACTIONS[action&.to_sym]
    return {} if entry.blank?
    article = (action == current) ? UPLOAD_ANOTHER : entry[:article]
    entry.merge(article: article)
  end

  # upload_action_link
  #
  # @param [String, Symbol, nil] action   The target action.
  # @param [String, Symbol, nil] current  The current `params[:action]`.
  # @param [String, nil]         label    Override #UPLOAD_ACTIONS label.
  # @param [String, nil]         path     Override #UPLOAD_ACTIONS action.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML link element.
  # @return [nil]                         If *action* not configured.
  #
  def upload_action_link(action = nil, current: nil, label: nil, path: nil)
    entry = upload_action_entry(action, current: current)
    return if entry.blank?
    path  ||= { action: entry[:action] }
    label ||= entry[:label]
    label  %= entry[:article]
    html_tag(:li, class: 'file-upload-action') do
      link_to_action(label, path: path)
    end
  end

  # List upload actions.  If the current action is provided, the associated
  # action link will be appear at the top of the list.
  #
  # @param [String, Symbol] current   Default: `params[:action]`
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_action_list(current: params[:action]&.to_sym)
    links =
      %i[new edit delete].map { |action|
        upload_action_link(action, current: current)
      }.compact
    if (first = links.index { |link| link.include?(UPLOAD_ANOTHER) })
      links.prepend(links.delete_at(first))
    end
    html_tag(:ul, class: 'file-upload-actions') { links }
  end

  # Supply an element containing a description for the current action context.
  #
  # @param [Symbol, String, nil] text     Specification of the text to display:
  #                                         Symbol: I18n lookup path
  #                                         String: literal text
  #                                         nil:    Locate the text for the
  #                                                   current action.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no text was provided or defined.
  #
  def upload_description(text = nil)
    opt = { item: :description }
    # noinspection RubyCaseWithoutElseBlockInspection
    case text
      when Symbol then opt[:path] = text
      when String then opt[:text] = text
    end
    upload_text_element(**opt)
  end

  # Supply an element containing directions for the current action context.
  #
  # @param [Symbol, String, nil] text     Specification of the text to display:
  #                                         Symbol: I18n lookup path
  #                                         String: literal text
  #                                         nil:    Locate the text for the
  #                                                   current action.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no text was provided or defined.
  #
  def upload_directions(text = nil)
    opt = { item: :directions, tag: :h2 }
    # noinspection RubyCaseWithoutElseBlockInspection
    case text
      when Symbol then opt[:path] = text
      when String then opt[:text] = text
    end
    upload_text_element(**opt)
  end

  # Supply an element containing additional notes for the current action.
  #
  # @param [Symbol, String, nil] text     Specification of the text to display:
  #                                         Symbol: I18n lookup path
  #                                         String: literal text
  #                                         nil:    Locate the text for the
  #                                                   current action.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no text was provided or defined.
  #
  def upload_notes(text = nil)
    opt = { item: :notes }
    # noinspection RubyCaseWithoutElseBlockInspection
    case text
      when Symbol then opt[:path] = text
      when String then opt[:text] = text
    end
    upload_text_element(**opt)
  end

  # Supply an element containing configured text for the current action.
  #
  # @param [String, Symbol] item          Default: 'text'.
  # @param [String]         text          Override text to display.
  # @param [String, Symbol] path          Override I18n path to use.
  # @param [String, Symbol] controller    Default: `params[:controller]`.
  # @param [String, Symbol] action        Default: `params[:action]`.
  # @param [String, Symbol] tag           Tag for the internal text block.
  # @param [Hash]           opt           Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no text was provided or defined.
  #
  def upload_text_element(
    item:       nil,
    text:       nil,
    path:       nil,
    controller: nil,
    action:     nil,
    tag:        :p,
    **opt
  )
    type = item&.to_s&.delete_suffix('_html') || 'text'
    text ||=
      page_description_text(controller: controller, action: action, type: type)
    return if text.blank?
    unless text.html_safe?
      text = ERB::Util.h(text)
      text = html_tag(tag, text) unless tag.nil?
    end
    opt = append_css_classes(opt, 'file-upload-text')
    append_css_classes!(opt, type) unless type == 'text'
    html_div(text, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current uploads.
  #
  # @return [Array<Upload>]
  #
  def upload_list
    page_items
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default link tooltip.
  #
  # @type [String]
  #
  UPLOAD_SHOW_TOOLTIP = I18n.t('emma.upload.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Upload] item
  # @param [Hash]   opt               Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_link(item, **opt)
    opt[:path]    = show_upload_path(id: item.id)
    opt[:tooltip] = UPLOAD_SHOW_TOOLTIP
    item_link(item, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render the contents of the :file_data field.
  #
  # @param [String, Hash, Upload] value
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If *value* did not have valid JSON.
  #
  #--
  # noinspection RubyYardParamTypeMatch
  #++
  def render_file_data(value)
    item  = (value if value.is_a?(Upload))
    value = item.file_data if item
    pairs = json_parse(value)
    render_json_data(item, pairs) if pairs
  end

  # Render the contents of the :emma_data field.
  #
  # @param [String, Hash, Upload] value
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If *value* did not have valid JSON.
  #
  #--
  # noinspection RubyYardParamTypeMatch
  #++
  def render_emma_data(value)
    item  = (value if value.is_a?(Upload))
    value = item.emma_data if item
    pairs = json_parse(value) or return
    pairs.transform_keys! { |k| SEARCH_RECORD_LABELS[k] || k }
    render_json_data(item, pairs)
  end

  # Render hierarchical data.
  #
  # @param [Model, nil]   item
  # @param [String, Hash] value
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If *value* was not valid JSON.
  #
  def render_json_data(item, value)
    return unless (pairs = json_parse(value))
    pairs.each_pair do |k, v|
      pairs[k] = render_json_data(item, v) if v.is_a?(Hash)
    end
    html_div(class: 'data-list') do
      # noinspection RubyYardParamTypeMatch
      render_field_values(item, model: :upload, pairs: pairs)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Upload] item
  # @param [*]      value
  #
  # @return [Field::Type]
  # @return [String]
  # @return [nil]
  #
  # @see ModelHelper#render_value
  #
  def upload_render_value(item, value)
    if !value.is_a?(Symbol)
      render_value(item, value)
    elsif item.is_a?(Upload) && item.field_names.include?(value)
      case value
        when :file_data then render_file_data(item) || '{}'
        when :emma_data then render_emma_data(item) || '{}'
        else                 item[value]            || EMPTY_VALUE
      end
    else
      Field.for(item, value) || render_value(item, value)
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render upload attributes.
  #
  # @param [Upload] item
  # @param [Hash]   opt               Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If *item* is blank.
  #
  def upload_details(item, opt = nil)
    pairs = UPLOAD_SHOW_FIELDS.merge(opt || {})
    item_details(item, :upload, pairs)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Upload] item
  # @param [Hash]   opt               Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_list_entry(item, opt = nil)
    pairs = UPLOAD_INDEX_FIELDS.merge(opt || {})
    item_list_entry(item, :upload, pairs)
  end

  # Include control icons below the entry number.
  #
  # @param [Upload]    item
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see ModelHelper#list_entry_number
  #
  def upload_list_entry_number(item, opt = nil)
    list_entry_number(item, opt) do
      upload_entry_icons(item)
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Upload action icon definitions.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  UPLOAD_ICONS = {
    edit: {
      icon: DELTA,
      tip:  'Modify this EMMA entry' # TODO: I18n
    },
    delete: {
      icon: HEAVY_X,
      tip:  'Delete this EMMA entry' # TODO: I18n
    }
  }.deep_freeze

  # Generate an element with icon controls for the operation(s) the user is
  # authorized to perform on the item.
  #
  # @param [Upload] item
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       If no operations are authorized.
  #
  # @see #upload_action_icon
  # @see #UPLOAD_ICONS
  #
  def upload_entry_icons(item, **opt)
    icons =
      # @type [Symbol] operation
      # @type [Hash]   properties
      UPLOAD_ICONS.map { |operation, properties|
        next unless can?(operation, Upload)
        action_opt = properties.merge(opt)
        action_opt[:id] ||= (item.id if item.respond_to?(:id))
        upload_action_icon(operation, **action_opt)
      }.compact
    html_span(class: 'icon-tray') { icons } if icons.present?
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
  # @option opt [String] :id
  # @option opt [String] :path
  # @option opt [String] :icon
  # @option opt [String] :tip
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML link element.
  # @return [nil]                         If *item* unrelated to a submission.
  #
  def upload_action_icon(op, **opt)
    id   = opt.delete(:id)
    path = opt.delete(:path) || (send("#{op}_upload_path", id: id) if id)
    return if path.blank?
    icon = opt.delete(:icon) || STAR
    tip  = opt.delete(:tip)
    opt  = prepend_css_classes(opt, 'icon', op.to_s)
    opt[:title] ||= tip
    # noinspection RubyYardParamTypeMatch
    make_link(icon, path, **opt)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Indicate whether the given field value produces an <input> that should be
  # disabled.
  #
  # @param [Symbol, String] field
  #
  # @see ModelHelper#readonly_form_field?
  #
  def upload_readonly_form_field?(field)
    Field.configuration(field)[:readonly].present?
  end

  # Indicate whether the given field value is required for validation.
  #
  # @param [Symbol, String] field
  #
  # @see ModelHelper#required_form_field?
  #
  def upload_required_form_field?(field)
    Field.configuration(field)[:required].present?
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Mapping of label keys to database fields and fields from
  # Search::Record::MetadataRecord.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  UPLOAD_FORM_FIELDS =
    UPLOAD_DATABASE_FIELDS
      .reject { |_, v| %i[file_data emma_data].include?(v) }
      .merge(SEARCH_RECORD_FIELDS)
      .freeze
=begin # TODO: use when configuration is transitioned...
  UPLOAD_FORM_FIELDS =
    UPLOAD_DATABASE_FIELDS
      .except(:file_data, :emma_data)
      .merge(SEARCH_RECORD_FIELDS)
      .deep_freeze
=end

  # Render pre-populated form fields.
  #
  # @param [Upload] item
  # @param [Hash]   opt               Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_form_fields(item, **opt)
    form_fields(item, :upload, UPLOAD_FORM_FIELDS.merge(opt))
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Button information for upload actions.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  UPLOAD_ACTION_VALUES =
    %i[new edit delete bulk_new bulk_edit bulk_delete].map { |action|
      [action, i18n_button_values(:upload, action)]
    }.to_h.deep_freeze

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
  def upload_form(item, label: nil, action: nil, **opt)
    action = (action || params[:action])&.to_sym
    opt, form_opt = partition_options(opt, :cancel)

    # noinspection RubyCaseWithoutElseBlockInspection
    case action
      when :new
        form_opt[:url]      = create_upload_path
      when :edit
        form_opt[:url]      = update_upload_path
        form_opt[:method] ||= :put
    end
    form_opt[:multipart]    = true
    form_opt[:autocomplete] = 'off'

    prepend_css_classes!(form_opt, 'file-upload-form', action.to_s)
    scroll_to_top_target!(form_opt)

    html_div(class: "file-upload-container #{action}") do
      # @type [ActionView::Helpers::FormBuilder] f
      form_with(model: item, **form_opt) do |f|
        data_opt = { class: 'upload-hidden' }

        # Communicate :file_data through the form as a hidden field.
        file_data = item&.active_file_data || item&.file_data
        file_data = data_opt.merge!(id: 'upload_file_data', value: file_data)
        file_data = f.hidden_field(:file, file_data)

        # Hidden data fields.
        emma_data = item&.active_emma_data || item&.emma_data
        emma_data = data_opt.merge!(id: 'upload_emma_data', value: emma_data)
        emma_data = f.hidden_field(:emma_data, emma_data)

        # Button tray.
        tray = []
        tray << upload_submit_button(action: action, label: label)
        tray << upload_cancel_button(action: action, url: opt[:cancel])
        tray << f.file_field(:file)
        tray << upload_filename_display
        tray = html_div(class: 'button-tray') { tray }

        # Field display selections.
        tabs = upload_field_group

        # Parent entry input control.
        parent_input = upload_parent_entry_select

        # Control elements which are always visible at the top of the input
        # form.
        controls = html_div(class: 'controls') { tray << tabs << parent_input }

        # Form fields.
        fields = upload_field_container(item)

        # All form sections.
        [emma_data, file_data, controls, fields].compact.join("\n").html_safe
      end
    end
  end

  # Upload submit button.
  #
  # @param [Hash] opt                 Passed to #submit_tag except for:
  #
  # @option opt [String, Symbol] :action    Default: `#params[:action]`.
  # @option opt [String]         :label     Default: based on :action.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see submitButton() in app/assets/javascripts/feature/download.js
  #
  def upload_submit_button(**opt)
    opt    = prepend_css_classes(opt, 'submit-button', 'uppy-FileInput-btn')
    action = (opt.delete(:action) || params[:action])&.to_sym
    values = UPLOAD_ACTION_VALUES[action]
    label  = opt.delete(:label) || values[:submit][:label]
    opt[:title] ||= values[:submit][:disabled][:tooltip]
    # noinspection RubyYardReturnMatch
    submit_tag(label, opt)
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
  # @see cancelButton() in app/assets/javascripts/feature/download.js
  #
  def upload_cancel_button(**opt)
    opt    = prepend_css_classes(opt, 'cancel-button', 'uppy-FileInput-btn')
    action = (opt.delete(:action) || params[:action])&.to_sym
    values = UPLOAD_ACTION_VALUES[action]
    label  = opt.delete(:label) || values[:cancel][:label]
    # Define the path for the cancel action.
    opt[:'data-path'] = opt.delete(:url) || params[:cancel]
    opt[:'data-path'] ||= (request.referer if local_request? && !same_request?)
    opt[:'data-path'] ||= upload_index_path
    opt[:title] ||= values[:cancel][:tooltip]
    opt[:type]  ||= 'reset'
    button_tag(label, opt)
  end

  # Element for displaying the name of the file that was uploaded.
  #
  # @param [String] leader            Text preceding the filename.
  # @param [Hash]   opt               Passed to #html_div for outer <div>.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_filename_display(leader: nil, **opt)
    opt = prepend_css_classes(opt, 'uploaded-filename')
    leader ||= 'Selected file:' # TODO: I18n
    html_div(opt) do
      html_span(leader, class: 'leader') << html_span('', class: 'filename')
    end
  end

  # Element name for field group radio buttons.
  #
  # @type [String]
  #
  UPLOAD_FIELD_GROUP_NAME = 'field-group'

  # Field group radio buttons and their labels and tooltips.
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
  # @see fieldDisplayFilterSelect() in javascripts/feature/download.js
  #
  def upload_field_group(**opt)
    name = UPLOAD_FIELD_GROUP_NAME
    opt  = prepend_css_classes(opt, 'upload-field-group')
    opt[:role] = 'radiogroup'
    html_div(opt) do
      UPLOAD_FIELD_GROUP.map do |group, properties|
        enabled = properties[:enabled].to_s
        next if false?(enabled)
        next if (enabled == 'debug') && !session_debug?

        input_id = "#{name}_#{group}"
        label_id = "label-#{input_id}"
        tooltip  = properties[:tooltip]
        selected = true?(properties[:default])

        i_opt = { role: 'radio', 'aria-labelledby': label_id }
        input = radio_button_tag(name, group, selected, i_opt)

        l_opt = { id: label_id }
        label = properties[:label] || group.to_s
        label = label_tag(input_id, label, l_opt)

        html_div(class: 'radio', title: tooltip) { input << label }
      end
    end
  end

  # Element for prompting for the EMMA index entry of the member repository
  # item which was the basis for the remediated item which is being submitted.
  #
  # @param [Hash] opt                 Passed to #html_div for outer <div>.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see monitorSourceRepository() in javascripts/feature/file-upload.js
  #
  def upload_parent_entry_select(**opt)
    opt    = prepend_css_classes(opt, 'parent-entry-select', 'hidden')
    id     = 'parent-entry-search'
    type   = :search
    t_id   = opt[:'aria-labelledby'] = "#{id}-title"
    title  =
      "Please indicate the EMMA entry for the original repository item. " \
      "If possible, enter the standard identifier (ISBN, ISSN, OCLC, etc.) " \
      "or the full title of the original work." # TODO: I18n
    title  = html_div(title, id: t_id, class: 'search-title')
    input  = search_input(id, type)
    submit = html_div(class: 'search-button') { search_button_label(type) }
    cancel = html_div(class: 'search-cancel') { 'Cancel' } # TODO: I18n
    html_div(**opt) { title << input << submit << cancel }
  end

  # Form fields are wrapped in an element for easier grid manipulation.
  #
  # @param [Upload] item
  # @param [Hash]   opt               Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_field_container(item, **opt)
    opt = prepend_css_classes(opt, 'upload-fields')
    html_div(opt) do
      upload_form_fields(item) << upload_no_fields_row
    end
  end

  # Text for #upload_no_fields_row. # TODO: I18n
  #
  # @type [String]
  #
  UPLOAD_NO_FIELDS = 'NO FIELDS'

  # Hidden row that is shown only when no field rows are being displayed.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_no_fields_row
    html_div(UPLOAD_NO_FIELDS, class: 'no-fields')
  end

  # ===========================================================================
  # :section: Item forms (edit/delete pages)
  # ===========================================================================

  public

  # Generate a menu of existing EMMA entries (uploaded items).
  #
  # @param [Symbol, String] action    Default: `#params[:action]`
  # @param [User, String]   user      Default: @user
  # @param [String]         prompt
  # @param [Hash]           opt       Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_items_menu(action: nil, user: nil, prompt: nil, **opt)
    action ||= params[:action]
    user   ||= @user
    user     = user.id if user.is_a?(User)
    prompt ||= 'Select an EMMA entry' # TODO: I18n

    path  = upload_action_entry(action)[:action] || action
    path  = send("#{path}_upload_path")

    items = user ? Upload.where(user_id: user) : Upload.all
    menu  = Array.wrap(items).map { |item| [upload_menu_label(item), item.id] }
    menu  = options_for_select(menu)
    select_opt = { prompt: prompt, onchange: 'this.form.submit();' }

    html_opt = prepend_css_classes(opt, 'select-entry', 'menu-control')
    html_opt[:method] ||= :get
    # noinspection RubyYardReturnMatch
    form_tag(path, html_opt) do
      select_tag(:selected, menu, select_opt)
    end
  end

  # ===========================================================================
  # :section: Item forms (edit/delete pages)
  # ===========================================================================

  protected

  # upload_menu_label
  #
  # @param [Upload] item
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_menu_label(item)
    index = item.id.to_s.presence
    file  = item.filename.presence
    name  = item.submission_id.presence
    index = "&thinsp;&nbsp;#{index}" if index && (index.size == 1)
    index = "Entry #{index}"         if index # TODO: I18n
    file  = ERB::Util.h(file)        if file
    name  = (name && file) ? "#{name} (#{file})" : (name || file)
    [index, name].join(' - ').html_safe
  end

  # ===========================================================================
  # :section: Item forms (delete pages)
  # ===========================================================================

  public

  UPLOAD_DELETE_OPTIONS        = %i[force truncate emergency].freeze
  UPLOAD_DELETE_FORM_OPTIONS   = [:cancel, *UPLOAD_DELETE_OPTIONS].freeze
  UPLOAD_DELETE_SUBMIT_OPTIONS = [:label,  *UPLOAD_DELETE_OPTIONS].freeze

  # Generate a form with controls for deleting a file and its entry.
  #
  # @param [Array<String,Upload>] items
  # @param [String]               label   Label for the submit button.
  # @param [Hash]                 opt     Passed to 'file-upload-delete' except
  #                                         for:
  #
  # @option opt [Boolean] :force          Passed to #upload_delete_submit
  # @option opt [Boolean] :truncate       Passed to #upload_delete_submit
  # @option opt [Boolean] :emergency      Passed to #upload_delete_submit
  # @option opt [String]  :cancel         Cancel button redirect URL passed to
  #                                         #upload_delete_cancel.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_delete_form(*items, label: nil, **opt)
    opt, html_opt = partition_options(opt, *UPLOAD_DELETE_FORM_OPTIONS)
    cancel = upload_delete_cancel(url: opt.delete(:cancel))
    submit = upload_delete_submit(*items, **opt.merge!(label: label))
    html_div(class: 'file-upload-container delete') do
      prepend_css_classes!(html_opt, 'file-upload-delete')
      html_div(html_opt) { submit << cancel }
    end
  end

  # Submit button for the delete upload form.
  #
  # @param [Array<String,Upload>] items
  # @param [String]               label   Override label for the submit button.
  # @param [Hash]                 opt     Passed to #button_to except for:
  #
  # @option opt [Boolean] :force          If *true*, add 'force=true' to
  #                                         the form submission URL.
  # @option opt [Boolean] :truncate       If *true*, add 'truncate=true' to
  #                                         the form submission URL.
  # @option opt [Boolean] :emergency      If *true*, add 'emergency=true' to
  #                                         the form submission URL.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_delete_submit(*items, label: nil, **opt)
    opt, html_opt = partition_options(opt, *UPLOAD_DELETE_SUBMIT_OPTIONS)
    opt[:force]     = force_delete     unless opt.key?(:force)
    opt[:truncate]  = truncate_delete  unless opt.key?(:truncate)
    opt[:emergency] = emergency_delete unless opt.key?(:emergency)
    action  = (opt.delete(:action) || params[:action])&.to_sym
    config  = UPLOAD_ACTION_VALUES.dig(action, :submit) || {}
    label ||= config[:label]
    ids     = Upload.compact_ids(*items).join(',').presence
    url     = (destroy_upload_path(**opt.merge!(id: ids)) if ids.present?)
    append_css_classes!(html_opt, (url ? 'best-choice' : 'forbidden'))
    prepend_css_classes!(html_opt, 'submit-button', 'uppy-FileInput-btn')
    html_opt[:title]  ||= config[:disabled][:tooltip]
    html_opt[:role]   ||= 'button'
    html_opt[:method] ||= :delete
    button_to(label, url, **html_opt)
  end

  # Cancel button for the delete upload form.
  #
  # @param [Hash] opt                 Passed to #upload_cancel_button
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see cancelAction() in app/assets/javascripts/feature/download.js
  #
  def upload_delete_cancel(**opt)
    opt[:action]  ||= :delete
    opt[:onclick] ||= 'cancelAction();'
    upload_cancel_button(**opt)
  end

  # ===========================================================================
  # :section: Bulk new/edit/delete pages
  # ===========================================================================

  public

  # Initially hidden container used by the client to display intermediate
  # results during the bulk upload.
  #
  # @param [Hash] opt                 Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_upload_results(**opt)
    opt = prepend_css_classes(opt, 'file-upload-results', 'hidden')
    html_div(**opt)
  end

  # ===========================================================================
  # :section: Bulk new/edit pages
  # ===========================================================================

  public

  # Labels for check boxes associated with transmitted parameters. # TODO: I18n
  #
  # @type [Hash{Symbol=>String}]
  #
  BULK_UPLOAD_OPTION_LABEL = {
    prefix: 'Title prefix:',
    batch:  'Batch size:'
  }.freeze

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
  def bulk_upload_form(label: nil, action: nil, **opt)
    action = (action || params[:action])&.to_sym
    opt, form_opt = partition_options(opt, :prefix, :batch, :cancel)
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

    html_div(class: "file-upload-container bulk #{action}") do
      # @type [ActionView::Helpers::FormBuilder] f
      prepend_css_classes!(form_opt, "file-upload-bulk #{action}")
      form_with(**form_opt) do |f|
        lines = []

        # === Batch title prefix input
        url_param = :prefix
        lines <<
          if session_debug?
            html_div(class: 'line') do
              f.label(url_param, BULK_UPLOAD_OPTION_LABEL[url_param]) <<
                f.text_field(url_param, value: opt[url_param].presence)
            end
          elsif opt[url_param].present?
            hidden_url_parameter(nil, url_param, opt[url_param])
          end

        # === Batch size control
        url_param = :batch
        lines <<
          html_div(class: 'line') do
            f.label(url_param, BULK_UPLOAD_OPTION_LABEL[url_param]) <<
              f.number_field(url_param, min: 0, value: opt[url_param].presence)
          end

        # === Form control panel
        lines <<
          html_div(class: 'form-controls') do
            controls_opt = { class: 'bulk' }
            button_opt   = controls_opt.merge(action: action)
            submit  = upload_submit_button(label: label,        **button_opt)
            cancel  = upload_cancel_button(url:   opt[:cancel], **button_opt)
            input   = bulk_upload_file_select(f, :source, **controls_opt)
            display = upload_filename_display(**controls_opt)
            prepend_css_classes!(controls_opt, 'button-tray')
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

  # bulk_upload_file_select
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           method
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see ActionView::Helpers::FormBuilder#label
  # @see ActionView::Helpers::FormBuilder#file_field
  #
  def bulk_upload_file_select(f, method, **opt)
    l_opt = { class: 'file-select', role: 'button', tabindex: 0 }
    l_opt = merge_html_options(opt, l_opt)
    label = f.label(method, 'Select', l_opt) # TODO: I18n

    i_opt = { class: 'uppy-FileInput-btn', tabindex: -1 }
    i_opt = merge_html_options(opt, i_opt)
    input = f.file_field(method, i_opt)

    html_div(class: 'uppy-FileInput-container bulk') do
      label << input
    end
  end

  # ===========================================================================
  # :section: Bulk delete page
  # ===========================================================================

  public

  # Generate a form with controls for getting a list of identifiers to pass on
  # to the "/upload/delete" page.
  #
  # @param [String,Array<String>,nil] ids
  # @param [String]         label         Label for the submit button.
  # @param [Hash]           opt           Passed to #form_with except for:
  #
  # @option opt [Boolean] :force          Force index delete option
  # @option opt [Boolean] :truncate       Reset database ID option
  # @option opt [Boolean] :emergency      Emergency force delete option
  # @option opt [String]  :cancel         URL for cancel button action.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_delete_form(label: nil, ids: nil, **opt)
    action = :bulk_delete
    ids    = Array.wrap(ids).compact.presence
    opt, form_opt = partition_options(opt, *UPLOAD_DELETE_FORM_OPTIONS)

    opt[:force]     = force_delete     unless opt.key?(:force)
    opt[:truncate]  = truncate_delete  unless opt.key?(:truncate)
    opt[:emergency] = emergency_delete unless opt.key?(:emergency)

    prepend_css_classes!(form_opt, 'file-upload-bulk', 'delete')
    form_opt[:url]          = delete_select_upload_path
    form_opt[:method]     ||= :get
    form_opt[:autocomplete] = 'off'
    form_opt[:local]        = true # Turns off "data-remote='true'".

    html_div(class: 'file-upload-container bulk delete') do
      # @type [ActionView::Helpers::FormBuilder] f
      form_with(**form_opt) do |f|
        lines = []

        # === Options
        lines << bulk_delete_option(f, opt.slice(:force))
        lines << bulk_delete_option(f, opt.slice(:truncate),  debug_only: true)
        lines << bulk_delete_option(f, opt.slice(:emergency), debug_only: true)

        # === Item selection input
        lines << bulk_delete_input(f, selected: ids)

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
  def find_in_index(*items, **)
    found = failed = []
    items = items.flatten.compact
    if items.present?
      result = IngestService.instance.get_records(*items)
      found  = result.records
      sids   = found.map(&:emma_repositoryRecordId)
      failed =
        items.reject do |item|
          sid =
            case item
              when Upload then item.submission_id
              when Hash   then item[:submission_id] || item['submission_id']
              else             item
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

  # Labels for check boxes associated with transmitted parameters. # TODO: I18n
  #
  # @type [Hash{Symbol=>String}]
  #
  BULK_DELETE_OPTION_LABEL = {
    force:
      'Attempt to remove index entries of items not in the database?',
    truncate:
      'Reset "uploads" id field to 1?' \
      ' (Applies only when all records are being removed.)',
    emergency:
      'Attempt to remove index entries for bogus non-EMMA items?',
  }.freeze

  # bulk_delete_option
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Hash]                             param_and_value
  # @param [Boolean]                          debug_only
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_delete_option(f, param_and_value, debug_only: false)
    url_param, value = param_and_value.first
    if debug_only && !session_debug?
      hidden_url_parameter(nil, url_param, value)
    else
      label = f.label(url_param, BULK_DELETE_OPTION_LABEL[url_param])
      check = f.check_box(url_param, checked: value)
      html_div(class: 'line') { check << label }
    end
  end

  # Labels for text fields associated with transmitted parameters. # TODO: I18n
  #
  # @type [Hash{Symbol=>String}]
  #
  BULK_DELETE_INPUT_LABEL = {
    selected: 'Items to delete:'
  }.freeze

  # bulk_delete_input
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Hash]                             param_and_value
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_delete_input(f, param_and_value)
    url_param, value = param_and_value.first
    label = f.label(url_param, BULK_DELETE_INPUT_LABEL[url_param])
    input = f.text_field(url_param, value: value)
    html_div(class: 'line') { label << input }
  end


end

__loading_end(__FILE__)
