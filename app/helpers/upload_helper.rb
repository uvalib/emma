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
  include ModelHelper
  include I18nHelper

  extend I18nHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  UPLOAD_URL          = '/upload'                 # GET /upload
  UPLOAD_CREATE_URL   = UPLOAD_URL                # POST /upload
  UPLOAD_ENDPOINT_URL = "#{UPLOAD_URL}/endpoint"  # POST /upload/endpoint

  UPLOAD_DRAG_TARGET_CSS = 'upload-drag_and_drop'
  UPLOAD_PREVIEW_CSS     = 'upload-preview'

  UPLOAD_PREVIEW_ENABLED = false  # TODO: upload preview ???

  UPLOAD_CREATE_VALUES   = i18n_button_values(:upload, :new).deep_freeze
  UPLOAD_UPDATE_VALUES   = i18n_button_values(:upload, :edit).deep_freeze
  UPLOAD_DELETE_VALUES   = i18n_button_values(:upload, :delete).deep_freeze

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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # CSS class for the preview element.
  #
  # @return [String]
  #
  def upload_preview_css
    UPLOAD_PREVIEW_CSS
  end

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
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If preview is not enabled.
  #
  def upload_preview(force = false)
    return unless force || preview_enabled?
    html_div('', class: UPLOAD_PREVIEW_CSS)
  end

  # List upload actions.  If the current action is provided, the associated
  # action link will be appear at the top of the list.
  #
  # @param [String, Symbol] current_action    Default: `params[:action]`
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_action_list(current_action = params[:action])
    # noinspection RubyCaseWithoutElseBlockInspection
    case (current_action = current_action&.to_sym)
      when :create  then current_action = :new
      when :update  then current_action = :edit
      when :destroy then current_action = :delete
    end
    actions = {
      new:    ['Upload %s new file' ,      'a'],  # TODO: I18n
      edit:   ['Modify %s existing entry', 'an'], # TODO: I18n
      delete: ['Remove %s existing entry', 'an'], # TODO: I18n
    }
    links = {}
    if actions.key?(current_action)
      label_string, _article = actions.delete(current_action)
      links[current_action] = label_string % 'another'
    end
    links.merge!(actions.transform_values { |v| v.shift % v.shift })
    html_tag(:ul, class: 'file-upload-actions') do
      links.map { |action, label|
        html_tag(:li, class: 'file-upload-action') do
          link_to_action(label, path: { action: "#{action}_select" })
        end
      }.join("\n").html_safe
    end
  end

  # Supply an element containing a description for the current action context.
  #
  # @param [Symbol, String, nil] text     Specification of the text to display:
  #                                         Symbol: I18n lookup path
  #                                         String: literal text
  #                                         nil:    Locate the text for the
  #                                                   current action.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If no text was defined.
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
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If no text was defined.
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
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If no text was defined.
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
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If no text was defined.
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
    if text.nil?
      controller ||= params[:controller]
      action     ||= params[:action]
      path       ||= ['emma', controller, action, type].join('.')
      text = I18n.t("#{path}_html", default: nil)
      text &&= text.html_safe
      text ||= I18n.t(path, default: nil)
      return if text.blank?
    end
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
    opt[:path]    = upload_path(id: item.id)
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
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
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
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
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
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def render_json_data(item, value)
    return unless (pairs = json_parse(value))
    pairs.each_pair do |k, v|
      pairs[k] = render_json_data(item, v) if v.is_a?(Hash)
    end
    html_div(class: 'data-list') do
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
  # @return [*]
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
        else                 item[value]            || EN_DASH
      end
    else
      case value
        when :emma_repository        then Field::Select.new(item, value)
        when :emma_formatFeature     then Field::Multi.new(item, value)
        when :dc_creator             then Field::Multi.new(item, :creators)
        when :dc_language            then Field::Select.new(item, value)
        when :dc_rights              then Field::Select.new(item, value)
        when :dc_provenance          then Field::Select.new(item, value)
        when :dc_format              then Field::Select.new(item, value)
        when :dc_type                then Field::Select.new(item, value)
        when :dc_subject             then Field::Collection.new(item, value)
        when :dcterms_dateAccepted   then Field::Single.new(item, value)
        when :dcterms_dateCopyright  then Field::Single.new(item, value)
        when :s_accessibilityFeature then Field::Multi.new(item, value)
        when :s_accessibilityControl then Field::Multi.new(item, value)
        when :s_accessibilityHazard  then Field::Multi.new(item, value)
        when :s_accessMode           then Field::Multi.new(item, value)
        when :s_accessModeSufficient then Field::Multi.new(item, value)
        else                              render_value(item, value)
      end
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
  # @return [ActiveSupport::SafeBuffer]
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
  # @param [Upload] item
  # @param [Hash]   opt
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

  # Generate an element with icon controls for the operation(s) the user is
  # authorized to perform on the item.
  #
  # @param [Upload] item
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If no operations are authorized.
  #
  # @see ModelHelper#list_entry_number
  #
  def upload_entry_icons(item, **opt)
    icons = []
    icons << upload_edit_icon(item, **opt)          if can?(:edit,   Upload)
    icons << upload_delete_icon(item, **opt)        if can?(:delete, Upload)
    html_span(safe_join(icons), class: 'icon-tray') if icons.present?
  end

  # upload_edit_icon
  #
  # @param [Upload] item
  # @param [Hash]   opt               Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_edit_icon(item, **opt)
    url  = edit_upload_path(id: item.id)
    icon = DELTA
    opt  = prepend_css_classes(opt, 'edit', 'icon')
    opt[:title] ||= 'Modify this EMMA entry' # TODO: I18n
    make_link(icon, url, **opt)
  end

  # upload_delete_icon
  #
  # @param [Model] item
  # @param [Hash]   opt               Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_delete_icon(item, **opt)
    url  = delete_upload_path(id: item.id)
    icon = HEAVY_X
    opt  = prepend_css_classes(opt, 'delete', 'icon')
    opt[:title] ||= 'Delete this EMMA entry' # TODO: I18n
    make_link(icon, url, **opt)
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

  # Fields that should not be user-editable.
  #
  # @type [Array<Symbol>]
  #
  UPLOAD_READONLY_FORM_FIELDS =
    UPLOAD_FORM_FIELDS.values.select { |field|
      Upload.readonly_field?(field)
    }.freeze
=begin # TODO: use when configuration is transitioned...
  UPLOAD_READONLY_FORM_FIELDS =
    UPLOAD_FORM_FIELDS.keys.select { |field|
      Upload.readonly_field?(field)
    }.freeze
=end

  # Fields that are required for form validation.
  #
  # @type [Array<Symbol>]
  #
  UPLOAD_REQUIRED_FORM_FIELDS =
    UPLOAD_FORM_FIELDS.values.select { |field|
      Upload.required_field?(field) unless Upload.readonly_field?(field)
    }.freeze
=begin # TODO: use when configuration is transitioned...
  UPLOAD_REQUIRED_FORM_FIELDS =
    UPLOAD_FORM_FIELDS.keys.select { |field|
      Upload.required_field?(field) unless Upload.readonly_field?(field)
    }.freeze
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

  # Fields that should not be user-editable.
  #
  # @return [Array<Symbol>]
  #
  # @see ModelHelper#readonly_form_fields
  #
  def upload_readonly_form_fields
    UPLOAD_READONLY_FORM_FIELDS
  end

  # Fields that are required for form validation.
  #
  # @return [Array<Symbol>]
  #
  # @see ModelHelper#required_form_fields
  #
  def upload_required_form_fields
    UPLOAD_REQUIRED_FORM_FIELDS
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

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
    opt    = prepend_css_classes(opt, "file-upload-form #{action}")
    cancel = opt.delete(:cancel)
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

    html_div(class: "file-upload-container #{action}") do
      form_with(model: item, **opt) do |f|
        data_opt = { class: 'upload-hidden' }

        # Communicate :file_data through the form as a hidden field.
        file_data = item&.file_data&.to_json
        file_data = data_opt.merge!(id: 'upload_file_data', value: file_data)
        file_data = f.hidden_field(:file, file_data)

        # Hidden data fields.
        emma_data = item&.emma_data
        emma_data = data_opt.merge!(id: 'upload_emma_data', value: emma_data)
        emma_data = f.hidden_field(:emma_data, emma_data)

        # Button tray.
        tray = []
        tray << upload_submit_button(action: action, label: label)
        tray << upload_cancel_button(action: action, url: cancel)
        tray << f.file_field(:file)
        tray << upload_filename_display
        tray = html_div(safe_join(tray), class: 'button-tray')

        # Field display selections.
        tabs = upload_field_control

        # Form buttons and display selection controls.
        controls = html_div(class: 'controls') { tray << tabs }

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
  # @see submitButton() in file-upload.js
  #
  def upload_submit_button(**opt)
    opt    = prepend_css_classes(opt, 'submit-button', 'uppy-FileInput-btn')
    label  = opt.delete(:label)
    action = (opt.delete(:action) || params[:action])&.to_sym
    values =
      case action
        when :delete then UPLOAD_DELETE_VALUES
        when :edit   then UPLOAD_UPDATE_VALUES
        else              UPLOAD_CREATE_VALUES
      end
    label       ||= values[:submit][:label]
    opt[:title] ||= values[:submit][:disabled][:tooltip]
    # noinspection RubyYardReturnMatch
    submit_tag(label, opt)
  end

  # Upload cancel button.
  #
  # @param [Hash] opt                 Passed to #button_tag except for:
  #
  # @option opt [String, Symbol] :action    Default: `#params[:action]`.
  # @option opt [String]         :label     Default: based on :action.
  # @option opt [String]         :url       Default: :back.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see cancelButton() in file-upload.js
  #
  def upload_cancel_button(**opt)
    opt    = prepend_css_classes(opt, 'cancel-button', 'uppy-FileInput-btn')
    label  = opt.delete(:label)
    action = (opt.delete(:action) || params[:action])&.to_sym

    # Get button attributes.
    values =
      case action
        when :delete then UPLOAD_DELETE_VALUES
        when :edit   then UPLOAD_UPDATE_VALUES
        else              UPLOAD_CREATE_VALUES
      end
    label       ||= values[:cancel][:label]
    opt[:title] ||= values[:cancel][:tooltip]
    opt[:type]  ||= 'reset'

    # Define the path for the cancel action.
    opt[:'data-path'] = opt.delete(:url)
    opt[:'data-path'] ||=
      case action
        when :delete then delete_select_upload_path
        when :edit   then edit_select_upload_path
        else              new_select_upload_path
      end

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

  # Element name for field control radio buttons.
  #
  # @type [String]
  #
  UPLOAD_FIELD_CONTROL_NAME = 'field-control'

  # Field control radio buttons and their labels and tooltips.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>String}}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  UPLOAD_FIELD_CONTROL_VALUES =
    I18n.t('emma.upload.field_control').deep_symbolize_keys.deep_freeze

  # Initially-selected field control radio button.
  #
  # @type [Symbol]
  #
  UPLOAD_FIELD_CONTROL_DEFAULT = :filled

  # Control for filtering which fields are displayed.
  #
  # @param [Hash] opt                 Passed to #html_div for outer <div>.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #UPLOAD_FIELD_CONTROL_VALUES
  # @see fieldDisplayFilter() in file-upload.js
  #
  def upload_field_control(**opt)
    name = UPLOAD_FIELD_CONTROL_NAME
    opt  = prepend_css_classes(opt, 'upload-field-control')
    opt[:role] = 'radiogroup'
    html_div(opt) do
      UPLOAD_FIELD_CONTROL_VALUES.map { |v, properties|
        input_id = "#{name}_#{v}"
        label_id = "label-#{input_id}"
        tooltip  = properties[:tooltip]
        selected = (v == UPLOAD_FIELD_CONTROL_DEFAULT)

        i_opt = { role: 'radio', 'aria-labelledby': label_id }
        input = radio_button_tag(name, v, selected, i_opt)

        l_opt = { id: label_id }
        label = properties[:label] || v.to_s
        label = label_tag(input_id, label, l_opt)

        html_div(class: 'radio', title: tooltip) { input << label }
      }.join("\n").html_safe
    end
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

  # Text for #upload_no_fields_row.
  #
  # @type [String]
  #
  UPLOAD_NO_FIELDS = 'NO FIELDS' # TODO: I18n

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
  def upload_items_menu(action: nil, user: nil, prompt: nil, **opt)
    action ||= params[:action]
    user   ||= @user
    user     = user.id if user.is_a?(User)
    prompt ||= 'Select an EMMA entry' # TODO: I18n

    items = user ? Upload.where(user_id: user) : Upload.all
    menu =
      Array.wrap(items).map do |item|
        id    = item.id.to_s
        name  = item.repository_id
        file  = item.filename
        index = id
        index = "&thinsp;&nbsp;#{index}"         if index.size == 1
        name  = "#{name} (#{ERB::Util.h(file)})" if file.present?
        label = "Entry #{index} - #{name}".html_safe # TODO: I18n
        value = id
        [label, value]
      end
    menu = options_for_select(menu)
    select_opt = { prompt: prompt, onchange: 'this.form.submit();' }

    path = send("#{action}_select_upload_path")
    html_opt = prepend_css_classes(opt, 'select-entry', 'menu-control')
    html_opt[:method] ||= :get
    form_tag(path, html_opt) do
      select_tag(:selected, menu, select_opt)
    end
  end

  # ===========================================================================
  # :section: Item forms (delete pages)
  # ===========================================================================

  public

  # Generate a form with controls for deleting a file and its entry.
  #
  # @param [Array<String,Upload>] items
  # @param [String]               label   Label for the submit button.
  # @param [Boolean]              force   @see #upload_delete_submit
  # @param [Hash]                 opt     Passed to 'file-upload-delete' except
  #                                         for:
  #
  # @option opt [String] :cancel          URL for cancel button action
  #                                         (default: :back).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_delete_form(*items, label: nil, force: nil, **opt)
    html_div(class: 'file-upload-container delete') do
      opt    = prepend_css_classes(opt, 'file-upload-delete')
      submit = upload_delete_submit(*items, label: label, force: force)
      cancel = upload_delete_cancel(url: opt.delete(:cancel))
      html_div(opt) { submit << cancel }
    end
  end

  # upload_delete_submit
  #
  # @param [Array<String,Upload>] items
  # @param [Hash]                 opt     Passed to #make_link except for:
  #
  # @option opt [String]  :label          Override link label.
  # @option opt [Boolean] :force          If *true*, add 'force=true' to the
  #                                         form submission URL.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def upload_delete_submit(*items, **opt)
    opt, html_opt = partition_options(opt, :label, :force)
    label = opt[:label] || UPLOAD_DELETE_VALUES[:submit][:label]
    ids   = Upload.collect_ids(*items).join(',').presence
    url   = ids ? upload_path(**opt.slice(:force).merge!(id: ids)) : ''
    prepend_css_classes!(html_opt, 'submit-button', 'uppy-FileInput-btn')
    append_css_classes!(html_opt, (url.presence ? 'best-choice' : 'forbidden'))
    html_opt[:'aria-role'] ||= 'button'
    html_opt[:method]      ||= :delete
    button_to(label, url, **html_opt)
  end

  # Upload upload_delete_cancel button.
  #
  # @param [Hash] opt                 Passed to #upload_cancel_button
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see cancelAction() in definitions.js
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

  # Generate a form with controls for uploading a file, entering metadata, and
  # submitting.
  #
  # @param [String]         label     Label for the submit button.
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [Hash]           opt       Passed to #form_with except for:
  #
  # @option opt [String] :cancel      URL for cancel button action (default:
  #                                     :back).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_upload_form(label: nil, action: nil, **opt)
    action = (action || params[:action])&.to_sym
    opt    = prepend_css_classes(opt, "file-bulk-upload-form #{action}")
    cancel = opt.delete(:cancel)

    # noinspection RubyCaseWithoutElseBlockInspection
    case action
      when :new
        opt[:url]      = bulk_create_upload_path
        opt[:method] ||= :post
      when :edit
        opt[:url]      = bulk_update_upload_path
        opt[:method] ||= :put
    end
    opt[:multipart]    = true
    opt[:autocomplete] = 'off'

    html_div(class: "file-upload-container bulk #{action}") do
      form_with(**opt) do |f|
        html_div(class: 'controls') do
          tray = []
          tray << upload_submit_button(action: action, label: label)
          tray << upload_cancel_button(action: action, url: cancel)
          tray << f.file_field(:source)
          tray << upload_filename_display
          html_div(safe_join(tray), class: 'button-tray')
        end
      end
    end
  end

end

__loading_end(__FILE__)
