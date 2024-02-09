# app/decorators/upload_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/upload" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Upload]
#
class UploadDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for Upload

  # ===========================================================================
  # :section: Definitions shared with UploadsDecorator
  # ===========================================================================

  public

  module SharedPathMethods

    include BaseDecorator::SharedPathMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def renew_path(item = nil, **opt)
      path_for(item, **opt, action: :renew)
    end

    def reedit_path(item = nil, **opt)
      path_for(item, **opt, action: :reedit)
    end

    def cancel_path(item = nil, **opt)
      path_for(item, **opt, action: :cancel)
    end

    def check_path(item = nil, **opt)
      path_for(item, **opt, action: :check)
    end

    def upload_path(*, **opt)
      h.upload_upload_path(**opt)
    end

    def bulk_index_path(item = nil, **opt)
      path_for(item, **opt, action: :bulk_index)
    end

    def bulk_new_path(item = nil, **opt)
      path_for(item, **opt, action: :bulk_new)
    end

    def bulk_create_path(item = nil, **opt)
      path_for(item, **opt, action: :bulk_create)
    end

    def bulk_edit_path(item = nil, **opt)
      path_for(item, **opt, action: :bulk_edit)
    end

    def bulk_update_path(item = nil, **opt)
      path_for(item, **opt, action: :bulk_update)
    end

    def bulk_delete_path(item = nil, **opt)
      path_for(item, **opt, action: :bulk_delete)
    end

    def bulk_destroy_path(item = nil, **opt)
      path_for(item, **opt, action: :bulk_destroy)
    end

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
    ITEM_NAME = UploadController.unit[:item]

    # Uploader properties.
    #
    # @type [Hash{Symbol=>String}]
    #
    UPLOADER = {
      drag_target: 'drag-drop-target',
      preview:     'item-preview',
    }.deep_freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Groupings of states related by theme.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    # @see file:config/locales/controllers/upload.en.yml
    #
    STATE_GROUP =
      Upload::WorkflowMethods::STATE_GROUP.transform_values do |entry|
        entry.map { |key, value|
          if %i[enabled show].include?(key)
            if value.nil? || true?(value)
              value = true
            elsif false?(value)
              value = false
            elsif value == 'nonzero'
              value = ->(list, group = nil) {
                list &&= list.select { |r| r.state_group == group } if group
                list.present?
              }
            end
          end
          [key, value]
        }.to_h
      end

    # CSS class for the state selection panel.
    #
    # @type [String]
    #
    GROUP_PANEL_CLASS = 'select-group-panel'

    # CSS class for the state group controls container.
    #
    # @type [String]
    #
    GROUP_CLASS = 'select-group'

    # CSS class for a control within the state selection panel.
    #
    # @type [String]
    #
    GROUP_CONTROL_CLASS = 'control'

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Control whether display list filtering is allowed.
    #
    # @type [Boolean]
    #
    LIST_FILTERING = false

    # CSS class for the state group list filter panel.
    #
    # @type [String]
    #
    LIST_FILTER_CLASS = 'list-filter-panel'

    # CSS class for the state group controls container.
    #
    # @type [String]
    #
    FILTER_GROUP_CLASS = 'filter-group'

    # CSS class for a control within the state group controls container.
    #
    # @type [String]
    #
    FILTER_CONTROL_CLASS = 'control'

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # CSS class for the debug-only panel of checkboxes to control filter
    # visibility.
    #
    # @type [String]
    #
    FILTER_OPTIONS_CLASS = 'filter-options-panel'

    # =========================================================================
    # :section: BaseDecorator::Configuration overrides
    # =========================================================================

    public

    # Get all configured record fields for the model, moving :emma_data
    # key/value pairs up to the top level alongside database fields.
    #
    # @param [Symbol, nil] type       Passed to super.
    #
    # @return [ActionConfig]
    #
    def model_form_fields(type = nil)
      json_fields, db_fields = partition_hash(super, *compound_fields)
      emma_data = json_fields[:emma_data]&.slice(*EMMA_DATA_FIELDS)
      db_fields.merge!(emma_data) if emma_data.present?
      ActionConfig.wrap(db_fields)
    end

    # Get all fields for a model instance table entry, moving :emma_data and
    # :file_data to the start of the result, followed by the other database
    # fields ending with :edit_emma_data and :edit_file_data (if present).
    #
    # @param [Symbol, nil] type       Passed to super.
    #
    # @return [ActionConfig]
    #
    def model_table_fields(type = nil)
      json_fields, db_fields = partition_hash(super, *compound_fields)
      fields = {}
      fields.merge!(json_fields.extract!(:emma_data))
      fields.merge!(json_fields.extract!(:file_data))
      fields.merge!(db_fields)
      fields.merge!(json_fields) if json_fields.present?
      ActionConfig.wrap(fields)
    end

    # =========================================================================
    # :section: BaseDecorator::Fields overrides
    # =========================================================================

    public

    # Database columns with hierarchical data.
    #
    # @return [Array<Symbol>]
    #
    def compound_fields
      %i[file_data emma_data edit_file_data edit_emma_data]
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the state group described by *properties* should be an
    # active state group selection.
    #
    # @param [Symbol, nil]        group
    # @param [Hash, nil]          properties
    # @param [Array<Upload>, nil] list
    #
    def active_state_group?(group, properties, list)
      return true if properties.blank?
      %i[enabled show].all? do |k|
        case (v = properties[k])
          when 'debug' then session_debug?
          when Proc    then v.call(list, group)
          else              v
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
      }.merge!(
        check: {
          icon:    BANG,
          tooltip: 'Check for an update to the status of this submission',
          enabled: ->(item) { item.try(:in_process?) },
        }
      ).deep_freeze

    # Icon definitions for this decorator.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def icon_definitions
      ICONS
    end

    # =========================================================================
    # :section: BaseDecorator::List overrides
    # =========================================================================

    public

    # Include control icons below the entry number.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def list_item_number(**opt)
      trace_attrs!(opt)
      super(**opt) do
        control_icon_buttons(index: opt[:index], except: :show)
      end
    end

    # The number of columns needed if *item* will be displayed horizontally.
    #
    # @param [any, nil] item          Model, Hash, Array; default: object.
    #
    # @return [Integer]
    #
    def list_item_columns(item = nil)
      item = object          if item.nil?
      item = item.attributes if item.is_a?(Model)
      item = item.keys       if item.is_a?(Hash)
      Array.wrap(item).reject { |v|
        case v
          when Symbol, String then /(file_data|emma_data)$/.match?(v)
          when FieldConfig    then v[:ignored]
        end
      }.size
    end

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    public

    # Generate a menu of upload instances.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def items_menu(**opt)
      trace_attrs!(opt)
      items_menu_role_constraints!(opt)
      opt[:sort] ||= { id: :desc } if administrator? || manager?
      super
    end

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    protected

    # Generate a prompt for #items_menu.
    #
    # @param [User, Symbol, nil] user
    #
    # @return [String]
    #
    def items_menu_prompt(user: nil, **)
      case user
        when nil, :all then config_text(:upload, :select_any)
        else                config_text(:upload, :select_own)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # @private
    FILE_NAME_CLASS = BaseDecorator::Form::FILE_NAME_CLASS

    # Element for displaying the name of the file that was uploaded.
    #
    # @param [String] leader          Text preceding the filename.
    # @param [String] css             Characteristic CSS class/selector.
    # @param [Hash]   opt             Passed to #html_div for outer *div*.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def uploaded_filename_display(leader: nil, css: FILE_NAME_CLASS, **opt)
      leader ||= config_text(:upload, :uploaded_file, :leader)
      leader   = html_span(leader, class: 'leader')
      filename = config_text(:upload, :uploaded_file, :blank)
      filename = html_span(filename, class: 'filename')
      prepend_css!(opt, css)
      trace_attrs!(opt)
      html_div(**opt) do
        leader << filename
      end
    end

    # =========================================================================
    # :section: BaseDecorator::Form overrides
    # =========================================================================

    public

    # Form action button configuration.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    def generate_form_actions(*)
      super(%i[new edit delete bulk_new bulk_edit bulk_delete])
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
    # @return [Upload::Options]
    #
    def options
      context[:options] || Upload::Options.new
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

class UploadDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Display preview of Shrine uploads.  NOTE: Not currently enabled.
  #
  # @type [Boolean]
  #
  PREVIEW_ENABLED = false

  # Indicate whether preview is enabled.
  #
  # === Usage Notes
  # Uppy preview is only for image files.
  #
  def preview_enabled?
    PREVIEW_ENABLED
  end

  # Supply an element to contain a preview thumbnail of an image file.
  #
  # @param [Boolean] force
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If preview is not enabled.
  #
  def preview(force = false)
    return unless force || preview_enabled?
    html_div('', class: UPLOADER[:preview])
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # These columns are generally empty or don't provide a lot of useful
  # information on the submission details display.
  #
  # @type [Array<String,Symbol,Regexp>]
  #
  FIELD_FILTERS = [:phase, /^edit/, /^review/].freeze

  # Fields and configurations augmented with a :value entry containing the
  # current field value.
  #
  # @param [Hash] opt                 Passed to super
  #
  # @return [Hash{Symbol=>FieldConfig}]
  #
  def list_field_values(**opt)
    opt[:except] ||= FIELD_FILTERS unless developer?
    trace_attrs!(opt)
    result = super

    # Move :file_data and :emma_data to the end.
    data   = result.extract!(*compound_fields).presence and result.merge!(data)

    phase  = result.delete(:phase)&.dig(:value)&.to_sym
    edit   = result.reject { |k, _| k.is_a?(Array) || !k.start_with?('edit') }
    state  = (phase == :edit) && edit[:edit_state]&.dig(:value)&.to_sym
    result[:state][:value] = state if state && (state != :canceled)
    result.except!(*edit.keys)
  end

  # Transform a field value for HTML rendering.
  #
  # @param [any, nil]    value
  # @param [Symbol, nil] field
  # @param [Hash]        opt          Passed to the render method or super.
  #
  # @return [Field::Type]
  # @return [String]
  # @return [nil]
  #
  def list_field_value(value, field:, **opt)
    return value if value.is_a?(ActiveSupport::SafeBuffer)
    return super unless value.present? && field.is_a?(Symbol)
    trace_attrs!(opt)
    case field
      when :file_data, :edit_file_data
        render_file_data(value, field: field, **opt)
      when :emma_data, :edit_emma_data
        render_emma_data(value, field: field, **opt)
      else
        value
    end || EMPTY_VALUE
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # details_container
  #
  # @param [Array] before             Optional elements before the details.
  # @param [Hash]  opt                Passed to super except:
  #
  # @option opt [Symbol, Array<Symbol>] :skip   Display aspects to avoid.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details_container(*before, **opt, &blk)
    skip = Array.wrap(opt.delete(:skip))
    before.prepend(cover(placeholder: false)) unless skip.include?(:cover)
    super
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
      when :file_data, :edit_file_data then table_file_data_value(value)
      when :emma_data, :edit_emma_data then table_emma_data_value(value)
      else                                  value
    end || EMPTY_VALUE
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Rendered table value for a :file_data field.
  #
  # @param [any, nil] value
  #
  # @return [String, nil]
  #
  def table_file_data_value(value)
    json_parse(value, log: false)&.dig(:metadata, :filename) if value.present?
  end

  # Rendered table value for an :emma_data field.
  #
  # @param [any, nil] value
  #
  # @return [String, nil]
  #
  def table_emma_data_value(value)
    json_parse(value, log: false)&.dig(:dc_title) if value.present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Called by SearchDecorator#edit_controls.
  #
  # @param [Model, Hash, String, Symbol] item
  # @param [Hash]                        opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def self.controls_for(item, **opt)
    entry = Upload.latest_for_sid(item, fatal: false)
    return unless entry && can?(:modify, entry)
    ctx = { context: opt.delete(:context) }
    dec = new(entry, context: ctx)
    dec.control_icon_buttons(id: entry.id, **opt)
  end

  # ===========================================================================
  # :section: BaseDecorator::Controls overrides
  # ===========================================================================

  protected

  # Produce an action icon based on either :path or :id.
  #
  # @param [Symbol] action
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def control_icon_button(action, **opt)
    return super unless action == :check
    super do |path, link_opt|
      check_status_popup(path, id: object.id, **link_opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Create a container with the repository ID displayed as a link but acting as
  # a popup toggle button and a popup panel which is initially hidden.
  #
  # @param [String, Symbol]  path
  # @param [String, Integer] id       Object identifier.
  # @param [String]          css      Characteristic CSS class/selector.
  # @param [Hash]            opt      To PopupHelper#inline_popup except:
  #
  # @option opt [Hash] :attr          Options for deferred content.
  # @option opt [Hash] :placeholder   Options for transient placeholder.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/shared/modal-base.js *ModalBase.toggleModal()*
  #
  def check_status_popup(path, id:, css: '.check-status-popup', **opt)
    icon   = opt.delete(:icon)
    p_opt  = opt.delete(:placeholder)
    attr   = opt.delete(:attr)&.dup || {}
    css_id = opt[:'data-iframe'] || attr[:id] || "popup-frame-#{id}"
    path   = send(path, id: id, modal: true) if path.is_a?(Symbol)

    opt[:'data-iframe'] = attr[:id] = css_id
    opt[:title]          ||= config_text(:upload, :check_status, :tooltip)
    opt[:control]        ||= {}
    opt[:control][:icon] ||= icon
    opt[:panel]  = append_css(opt[:panel], 'refetch z-order-capture')
    opt[:resize] = false unless opt.key?(:resize)

    prepend_css!(opt, css)
    inline_popup(**opt) do
      p_opt = prepend_css(p_opt, 'iframe', POPUP_DEFERRED_CLASS)
      p_opt[:'data-path'] = path
      p_opt[:'data-attr'] = attr.to_json
      p_txt   = p_opt.delete(:text)
      p_txt ||= config_text(:upload, :check_status, :placeholder)
      html_div(p_txt, **p_opt)
    end
  end

  # ===========================================================================
  # :section: BaseDecorator::Form overrides
  # ===========================================================================

  public

  # Generate a form with controls for uploading a file, entering metadata, and
  # submitting.
  #
  # @param [Hash] opt                 Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def model_form(**opt)
    opt.reverse_merge!(uploader: true)
    super
  end

  # ===========================================================================
  # :section: BaseDecorator::Form overrides
  # ===========================================================================

  public

  # Screen-reader-only label for file input.  (This is to satisfy accessibility
  # checkers which don't ignore the file input which is made invisible in favor
  # of the Uppy file input control).
  #
  # @type [String]
  #
  FILE_LABEL = config_item("emma.#{model_type}.new.select.label").freeze

  # Single-select menu - drop-down.
  #
  # @param [String]      name
  # @param [Array]       value
  # @param [Hash]        opt          Passed to super
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_menu_single(name, value, **opt)
    form_menu_role_constraints!(opt)
    super(name, value, **opt)
  end

  # Control elements always visible at the top of the input form.
  #
  # @param [ActionView::Helpers::FormBuilder, nil] f
  # @param [Array<ActiveSupport::SafeBuffer>]      buttons
  # @param [Hash]                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_top_controls(f, *buttons, **opt)
    trace_attrs!(opt)
    t_opt = trace_attrs_from(opt)
    super do |parts|
      parts << parent_entry_select(**t_opt)
    end
  end

  # form_top_button_tray
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Array<ActiveSupport::SafeBuffer>] buttons
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_top_button_tray(f, *buttons, **opt)
    trace_attrs!(opt)
    t_opt = trace_attrs_from(opt)
    super do |parts|
      parts << f.label(:file, FILE_LABEL, class: 'sr-only', id: 'fi_label')
      parts << f.file_field(:file)
      parts << uploaded_filename_display(**t_opt)
      parts << lookup_control(**t_opt)
    end
  end

  # Upload cancel button.
  #
  # @param [Hash] opt                 Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def cancel_button(**opt)
    opt[:'data-path'] ||= opt.delete(:url) || context[:cancel] || back_path
    super
  end

  # Data for hidden form fields.
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def form_hidden(**opt)
    # Extra information to support reverting the record when canceled.
    #rev_data  = object.get_revert_data.to_json # TODO: is this still needed?
    rev_data  = '' # TODO: ??? (The only relevant Upload field would be :updated_at)

    # Communicate :file_data through the form as a hidden field.
    file_data = object.file_data

    # Hidden data fields.
    emma_data = object.emma_data

    super do |result, attr|
      result.merge!(
        revert_data: attr.merge(id: 'revert_data',     value: rev_data),
        file_data:   attr.merge(id: 'entry_file_data', value: file_data),
        emma_data:   attr.merge(id: 'entry_emma_data', value: emma_data)
      )
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Element for prompting for the EMMA index entry of the partner repository
  # item which was the basis for the remediated item which is being submitted.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_div for outer *div*.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LayoutHelper::SearchBar#search_input
  # @see LayoutHelper::SearchBar#search_button_label
  # @see file:javascripts/feature/model-form.js *monitorSourceRepository()*
  #
  def parent_entry_select(css: '.parent-entry-select', **opt)
    trace_attrs!(opt)
    t_opt  = trace_attrs_from(opt)
    b_opt  = { role: 'button', tabindex: 0 }
    id     = 'parent-entry-search'

    # Directions.
    t_id   = "#{id}-title"
    title  = config_text(:upload, :parent_select, :title)
    title  = html_div(title, id: t_id, class: 'search-title')

    # Text input.
    ctrlr  = :search
    input  = h.search_input(id, ctrlr, 'aria-labelledby': t_id)

    # Submit button.
    submit = h.search_button_label(ctrlr)
    submit = html_div(submit, class: 'search-button', **b_opt, **t_opt)

    # Cancel button.
    cancel = config_text(:upload, :parent_select, :cancel)
    cancel = html_div(cancel, class: 'search-cancel', **b_opt, **t_opt)

    opt[:'aria-describedby'] ||= t_id
    prepend_css!(opt, css, 'hidden')
    html_div(**opt) do
      title << input << submit << cancel
    end
  end

  # ===========================================================================
  # :section: BaseDecorator overrides
  # ===========================================================================

  public

  # Client-side scripting which are supplied via 'assets:precompile'.
  #
  # @return [Hash]
  #
  # @see file:app/assets/javascripts/shared/assets.js.erb  *Emma.Upload*
  #
  def self.js_properties
    path_properties = {
      renew:        renew_path,
      reedit:       reedit_path,
      check:        check_path(id: JS_ID),
      cancel:       cancel_path,
      upload:       upload_path,
      bulk_index:   bulk_index_path,
      bulk_new:     bulk_new_path,
      bulk_create:  bulk_create_path,
      bulk_edit:    bulk_edit_path,
      bulk_update:  bulk_update_path,
      bulk_delete:  bulk_delete_path,
      bulk_destroy: bulk_destroy_path,
    }
    super.deep_merge!(Path: path_properties)
  end

end

__loading_end(__FILE__)
