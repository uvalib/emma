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

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Uploader properties.
    #
    # @type [Hash{Symbol=>String}]
    #
    UPLOADER = {
      drag_target: 'drag-drop-target',
      preview:     'item-preview',
    }.deep_freeze

    # =========================================================================
    # :section: Item list (index page) support
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
    # :section: Item list (index page) support
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
    # :section: Item list (index page) support
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

    # Get all configured record fields for the model.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def model_form_fields(**)
      other, db_fields = partition_hash(super, :file_data, :emma_data)
      emma_data = other[:emma_data]&.except(*Field::PROPERTY_KEYS) || {}
      emma_data.select! { |_, v| v.is_a?(Hash) }
      db_fields.merge!(emma_data)
    end

    # =========================================================================
    # :section: Item list (index page) support
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
    # @type [Hash{Symbol=>Hash{Symbol=>*}}]
    #
    # @see BaseDecorator::Controls#ICON_PROPERTIES
    #
    ICONS =
      BaseDecorator::Controls::ICONS.except(:show).transform_values { |v|
        v.dup.tap do |entry|
          tip = entry[:tooltip]
          entry[:tooltip] %= { item: 'EMMA entry' } if tip&.include?('%')
          entry[:active] = true
        end
      }.reverse_merge!(
        check: {
          icon:    BANG,
          tooltip: 'Check for an update to the status of this submission',
          active:  ->(item) { item.try(:in_process?) },
        }
      ).deep_freeze

    # Icon definitions for this decorator.
    #
    # @return [Hash{Symbol=>Hash{Symbol=>*}}]
    #
    def icon_definitions
      ICONS
    end

    # =========================================================================
    # :section: BaseDecorator::List overrides
    # =========================================================================

    public

    # Render a single entry for use within a list of items.
    #
    # @param [Hash, nil] pairs        Additional field mappings.
    # @param [Hash]      opt          Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def list_item(pairs: nil, **opt)
      opt[:pairs] = model_index_fields.merge(pairs || {})
      super(**opt)
    end

    # Include control icons below the entry number.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def list_item_number(**opt)
      super(**opt) do
        control_icon_buttons(**opt.slice(:index))
      end
    end

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    public

    # Generate a menu of user instances.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def items_menu(**opt)
      hash = opt[:constraint]
      user = hash&.values_at(:user, :user_id)&.first
      org  = hash&.values_at(:org, :org_id)&.first
      unless user || org
        user = current_user
        org  = user&.org
        add  = {}
        case
          when administrator? then #add[:user] = :all
          when manager?       then add[:org]  = org
          when org            then add[:org]  = org
          when user           then add[:user] = user
          else                     add[:user] = :none
        end
        opt[:constraint] = hash&.reverse_merge(add) || add if add.present?
      end
      opt[:sort] ||= { id: :desc } if administrator? || manager?
      super(**opt)
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
        when nil, :all then 'Select an existing EMMA entry'    # TODO: I18n
        else                'Select an EMMA entry you created' # TODO: I18n
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
      leader ||= 'Selected file:' # TODO: I18n
      leader   = html_span(leader, class: 'leader')
      filename = html_span('', class: 'filename')
      prepend_css!(opt, css)
      html_div(opt) do
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

  # Transform a field value for HTML rendering.
  #
  # @param [*]         value
  # @param [Symbol, *] field
  # @param [Hash]      opt            Passed to the render method or super.
  #
  # @return [Field::Type]
  # @return [String]
  # @return [nil]
  #
  def render_value(value, field:, **opt)
    if present? && field.is_a?(Symbol) && object.include?(field)
      case field
        when :file_data then render_file_data(**opt)
        when :emma_data then render_emma_data(**opt)
        else                 object[field] || EMPTY_VALUE
      end
    end || super
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # details_container
  #
  # @param [Array]         added      Optional elements after the details.
  # @param [Array<Symbol>] skip       Display aspects to avoid.
  # @param [Hash]          opt        Passed to super
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details_container(*added, skip: [], **opt, &block)
    skip = Array.wrap(skip)
    full = !skip.include?(:cover)
    added.prepend(cover(placeholder: false)) if full
    super(*added, **opt, &block)
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  protected

  # These columns are generally empty or don't provide a lot of useful
  # information on the submission details display.
  #
  # @type [Array<String,Symbol,Regexp>]
  #
  FIELD_FILTERS = [:phase, /^edit/, /^review/].freeze

  # Specified field selections from the given User instance.
  #
  # @param [User, Hash, nil] item     Default: `#object`.
  # @param [Hash]            opt      Passed to super.
  #
  # @return [Hash{Symbol=>*}]
  #
  def model_field_values(item = nil, **opt)
    opt[:filter] ||= FIELD_FILTERS
    super
  end

  # ===========================================================================
  # :section: Item list (index page) support
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
    entry = Upload.latest_for_sid(item, no_raise: true)
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
    ph_opt = opt.delete(:placeholder)
    attr   = opt.delete(:attr)&.dup || {}
    css_id = opt[:'data-iframe'] || attr[:id] || "popup-frame-#{id}"
    path   = send(path, id: id, modal: true) if path.is_a?(Symbol)

    opt[:'data-iframe'] = attr[:id] = css_id
    opt[:title]          ||= 'Check the status of this submission' # TODO: I18n
    opt[:control]        ||= {}
    opt[:control][:icon] ||= icon
    opt[:panel]  = append_css(opt[:panel], 'refetch z-order-capture')
    opt[:resize] = false unless opt.key?(:resize)

    prepend_css!(opt, css)
    inline_popup(**opt) do
      ph_opt = prepend_css(ph_opt, 'iframe', POPUP_DEFERRED_CLASS)
      ph_opt[:'data-path'] = path
      ph_opt[:'data-attr'] = attr.to_json
      ph_txt = ph_opt.delete(:text) || 'Checking...' # TODO: I18n
      html_div(ph_txt, ph_opt)
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
    opt[:uploader] = true unless opt.key?(:uploader)
    super(**opt)
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
  FILE_LABEL = I18n.t("emma.#{model_type}.new.select.label").freeze

  # Control elements always visible at the top of the input form.
  #
  # @param [ActionView::Helpers::FormBuilder, nil] f
  # @param [Array<ActiveSupport::SafeBuffer>]      buttons
  # @param [Hash]                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_top_controls(f, *buttons, **opt)
    super { |parts| parts << parent_entry_select }
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
    super do |parts|
      parts << f.label(:file, FILE_LABEL, class: 'sr-only', id: 'fi_label')
      parts << f.file_field(:file)
      parts << uploaded_filename_display
      parts << lookup_control
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
    super(**opt)
  end

  # Data for hidden form fields.
  #
  # @param [Hash] opt
  #
  # @return [Hash{Symbol=>*}]
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

  # Element for prompting for the EMMA index entry of the member repository
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
    id     = 'parent-entry-search'
    b_opt  = { role: 'button', tabindex: 0 }

    # Directions.
    t_id   = "#{id}-title"
    title  =
      'Please indicate the EMMA entry for the original repository item. ' \
      'If possible, enter the standard identifier (ISBN, DOI, OCLC, etc.) ' \
      'or the full title of the original work.' # TODO: I18n
    title  = html_div(title, id: t_id, class: 'search-title')

    # Text input.
    ctrlr  = :search
    input  = h.search_input(id, ctrlr, 'aria-labelledby': t_id)

    # Submit button.
    submit = h.search_button_label(ctrlr)
    submit = html_div(submit, b_opt.merge(class: 'search-button'))

    # Cancel button.
    cancel = 'Cancel' # TODO: I18n
    cancel = html_div(cancel, b_opt.merge(class: 'search-cancel'))

    opt[:'aria-describedby'] ||= t_id
    prepend_css!(opt, css, 'hidden')
    html_div(opt) do
      title << input << submit << cancel
    end
  end

  # ===========================================================================
  # :section: BaseDecorator overrides
  # ===========================================================================

  public

  # Client-side scripting which are supplied via 'assets:precompile'.
  #
  # @param [Hash{Symbol=>*}]
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
