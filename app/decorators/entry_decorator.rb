# app/decorators/entry_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/entry" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Entry]
#
class EntryDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for Entry

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Paths

    include BaseDecorator::Paths

    # =========================================================================
    # :section: BaseDecorator::Paths overrides
    # =========================================================================

    public

    def index_path(*, **opt)
      h.entry_index_path(**opt)
    end

    def show_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      h.show_entry_path(**opt)
    end

    def new_path(*, **opt)
      h.new_entry_path(**opt)
    end

    def create_path(*, **opt)
      h.create_entry_path(**opt)
    end

    def edit_select_path(**opt)
      h.edit_select_entry_path(**opt)
    end

    def edit_path(item = nil, **opt)
      if opt[:selected]
        edit_select_path(**opt)
      else
        opt[:id] = id_for(item, **opt)
        h.edit_entry_path(**opt)
      end
    end

    def update_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      h.update_entry_path(**opt)
    end

    def delete_select_path(**opt)
      h.delete_select_entry_path(**opt)
    end

    def delete_path(item = nil, **opt)
      if opt[:selected]
        delete_select_path(**opt)
      else
        opt[:id] = id_for(item, **opt)
        h.delete_entry_path(**opt)
      end
    end

    def destroy_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      h.destroy_entry_path(**opt)
    end

    def renew_path(*, **opt)
      h.renew_entry_path(**opt)
    end

    def reedit_path(*, **opt)
      h.reedit_entry_path(**opt)
    end

    def cancel_path(*, **opt)
      h.cancel_entry_path(**opt)
    end

    def check_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      h.check_entry_path(**opt)
    end

    def endpoint_path(*, **opt)
      h.entries_path(**opt)
    end

    def bulk_index_path(*, **opt)
      h.bulk_entry_index_path(**opt)
    end

    def bulk_new_path(*, **opt)
      h.bulk_new_entry_path(**opt)
    end

    def bulk_create_path(*, **opt)
      h.bulk_create_entry_path(**opt)
    end

    def bulk_edit_path(*, **opt)
      h.bulk_edit_entry_path(**opt)
    end

    def bulk_update_path(*, **opt)
      h.bulk_update_entry_path(**opt)
    end

    def bulk_delete_path(*, **opt)
      h.bulk_delete_entry_path(**opt)
    end

    def bulk_destroy_path(*, **opt)
      h.bulk_destroy_entry_path(**opt)
    end

  end

  module Methods

    include BaseDecorator::Methods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Uploader properties.
    #
    # @type [Hash{Symbol=>String}]
    #
    UPLOAD = {
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
    # @see file:config/locales/controllers/entry.en.yml *en.emma.entry.state_group*
    #
    STATE_GROUP =
      Record::Steppable::STATE_GROUP.transform_values do |entry|
        entry.map { |key, value|
          if %i[enabled show].include?(key)
            if value.nil? || true?(value)
              value = true
            elsif false?(value)
              value = false
            elsif value == 'nonzero'
              value = ->(list, group = nil) {
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
    # @param [Symbol, nil]       group
    # @param [Hash, nil]         properties
    # @param [Array<Entry>, nil] list
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
    # :section: BaseDecorator::Links overrides
    # =========================================================================

    public

    # Control icon definitions.
    #
    # @type [Hash{Symbol=>Hash{Symbol=>Any}}]
    #
    CONTROL_ICONS =
      BaseDecorator::Links::CONTROL_ICONS.except(:show).transform_values { |v|
        v.dup.tap do |entry|
          entry[:tip] %= { item: 'EMMA entry' } if entry[:tip]&.include?('%')
          entry[:enabled] = true
        end
      }.reverse_merge!(
        check: {
          icon:    BANG,
          tip:     'Check for an update to the status of this submission',
          enabled: ->(item) { item.try(:in_process?) },
        }
      ).deep_freeze

    # Control icon definitions.
    #
    # @return [Hash{Symbol=>Hash{Symbol=>Any}}]
    #
    def control_icons
      super(icons: CONTROL_ICONS)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The CSS class selector associated with bibliographic lookup buttons.
    #
    # @type [String]
    #
    # @see file:javascripts/shared/modal-dialog.js ModalDialog.SELECTOR_ATTR
    #
    LOOKUP_CSS_SELECTOR = '.lookup-popup'

    # The JavaScript ModalDialog subclass for bibliographic lookup popups.
    #
    # @type [String]
    #
    # @see file:javascripts/shared/modal-dialog.js ModalDialog.CLASS_ATTR
    # @see file:javascripts/shared/lookup-modal.js LookupModal
    #
    LOOKUP_JS_CLASS = 'LookupModal'

    # Bibliographic lookup control which engages #lookup_modal.
    #
    # In addition to creating the control, this method also adds the modal to
    # the page modals (unless it already has been added).
    #
    # @param [Hash] opt               Passed to #lookup_modal except for:
    #
    # @option opt [Hash] :button      Options for #lookup_button_options.
    #
    # @see LayoutHelper::PageModals#add_page_modal
    #
    def lookup_control(**opt)
      css      = LOOKUP_CSS_SELECTOR
      js       = LOOKUP_JS_CLASS
      sel_opt  = { 'data-modal-selector': css, 'data-modal-class': js }
      btn_opt  = opt.delete(:button) || {}
      h.add_page_modal(css) { lookup_modal(**opt, **sel_opt) }
      make_popup_toggle(button: lookup_button_options(**btn_opt, **sel_opt))
    end

    # A modal popup for bibliographic lookup.
    #
    # @param [Hash] opt               Passed to #modal_popup except for:
    #
    # @option opt [Hash] :container   Options for #lookup_container.
    #
    def lookup_modal(**opt)
      css   = LOOKUP_CSS_SELECTOR
      c_opt = opt.delete(:container) || {}
      opt[:controls] = lookup_commit_button
      opt[:close]    = lookup_cancel_options
      prepend_css!(opt, css)
      modal_popup(**opt) do
        lookup_container(**c_opt)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Element for displaying the name of the file that was uploaded.
    #
    # @param [String] leader          Text preceding the filename.
    # @param [Hash]   opt             Passed to #html_div for outer *div*.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def uploaded_filename_display(leader: nil, **opt)
      css      = '.uploaded-filename'
      leader ||= 'Selected file:' # TODO: I18n
      leader   = html_span(leader, class: 'leader')
      filename = html_span('', class: 'filename')
      prepend_css!(opt, css)
      html_div(opt) do
        leader << filename
      end
    end

    # Bibliographic lookup popup.
    #
    # @param [Hash] opt               Passed to #inline_popup except for:
    #
    # @option opt [Hash] :button      Options for #lookup_button_options.
    # @option opt [Hash] :container   Options for #lookup_container.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see file:app/assets/javascripts/feature/model-form.js *lookupButton()*
    #
    def lookup_popup(**opt)
      css   = LOOKUP_CSS_SELECTOR
      b_opt = opt.delete(:button)    || {}
      c_opt = opt.delete(:container) || {}
      unless opt.dig(:control, :button).present?
        opt[:control] = opt[:control]&.dup || {}
        opt[:control][:button] = lookup_button_options(**b_opt)
      end
      opt[:controls] = lookup_commit_button
      opt[:close]    = lookup_cancel_options
      prepend_css!(opt, css)
      inline_popup(**opt) do
        lookup_container(**c_opt)
      end
    end

    # lookup_commit_button
    #
    # @param [Hash] opt
    #
    # @option opt [Hash] :label       Override the default button label.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def lookup_commit_button(**opt)
      css   = '.commit'
      label = opt.delete(:label) || 'Update' # TODO: I18n
      opt[:type]  ||= 'submit'
      opt[:title] ||= 'Replace submission field values with these changes' # TODO: I18n
      prepend_css!(opt, css)
      html_button(label, opt)
    end

    # lookup_cancel_options
    #
    # @param [Hash] opt
    #
    # @return [Hash]
    #
    def lookup_cancel_options(**opt)
      opt[:label] ||= 'Cancel' # TODO: I18n
      opt[:title] ||= "Don't make any changes to submission field values" # TODO: I18n
      opt
    end

    # The options to create a toggle button to activate the bibliographic
    # lookup popup.
    #
    # @param [Hash] opt
    #
    # @option opt [Hash] :label       Override the default button label.
    #
    # @return [Hash]
    #
    # @see PopupHelper#inline_popup
    #
    def lookup_button_options(**opt)
      css = '.lookup-button'
      prepend_css!(opt, css)
      opt[:label] ||= 'Lookup' # TODO: I18n
      opt
    end

    # The content element of the bibliographic lookup popup.
    #
    # @param [Hash] opt               Passed to the outermost #html_div.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @note This does not address dynamic results entries.
    #
    # @see file:app/assets/javascripts/shared/lookup-modal.js *LookupModal*
    #
    def lookup_container(**opt)
      css = '.lookup-container'

      query_panel       = 'lookup-query'
      query_terms       = 'terms'
      status_panel      = 'lookup-status'
      notice            = 'notice'
      services          = 'services'
      entries           = 'lookup-entries'
      prompt            = 'lookup-prompt'
      heading           = 'lookup-heading'
      output            = 'lookup-output'
      terms             = 'item-terms'
      separator         = 'item-separator'
      results           = 'item-results'
      errors            = 'item-errors'
      diagnostics       = 'item-diagnostics'

      query_panel_css   = query_panel
      query_terms_css   = query_terms
      status_panel_css  = status_panel
      services_css      = "#{services} invisible"
      notice_css        = notice
      entries_css       = entries
      prompt_css        = prompt
      heading_css       = heading
      output_css        = output
      terms_css         = terms
      separator_css     = separator
      results_css       = "#{results} value"
      errors_css        = "#{errors} value"
      diagnostics_css   = "#{diagnostics} value"

      unique            = hex_rand
      heading_id        = "#{heading}-#{unique}"
      terms_id          = "#{terms}-#{unique}"
      separator_id      = "#{separator}-#{unique}"
      results_id        = "#{results}-#{unique}"
      errors_id         = "#{errors}-#{unique}"
      diagnostics_id    = "#{diagnostics}-#{unique}"

      query_label       = 'Query'           # TODO: I18n
      terms_label       = 'Query'           # TODO: I18n
      lookup_label      = 'Lookup'          # TODO: I18n
      separators_label  = 'Term Separators' # TODO: I18n
      services_label    = 'Searching:'      # TODO: I18n
      heading_label     = 'Results'         # TODO: I18n
      errors_label      = 'Errors'          # TODO: I18n
      diagnostics_label = 'Diagnostics'     # TODO: I18n

      separators = {
        space: 'Space, tab, and <strong>|</strong> (pipe)'.html_safe,
        pipe:  'Only <strong>|</strong> (pipe)'.html_safe
      }
      selected = :space

      # == Query
      query_panel =
        html_div(class: query_panel_css) do
          label = html_tag(:label, query_label)
          text  = html_div(class: query_terms_css)
          label << text
        end

      # == Input controls
      prompt =
        html_div(class: prompt_css) do
          terms_input =
            html_div(class: terms_css) do
              input  = h.text_field_tag('terms', nil, id: terms_id)
              label  = "#{terms_label}:"
              label  = h.label_tag(terms_id, label)
              button = lookup_label
              button = h.button_tag(button, type: 'button', class: 'submit')
              label << input << button
            end
          separator_choices =
            html_tag(:fieldset, id: separator_id, class: separator_css) do
              name = 'separator'
              separators.map.with_index { |(value, text), index|
                id      = "#{separator_id}-#{index}"
                checked = selected ? (value == selected) : index.zero?
                button  = h.radio_button_tag(name, value, checked, id: id)
                label   = h.label_tag(id, text)
                button << label
              }.unshift(html_tag(:legend, separators_label))
            end
          terms_input << separator_choices
        end

      # == Status display
      status =
        html_div(class: status_panel_css) do
          notice   = html_div(class: notice_css)
          services =
            html_div(class: services_css) do
              html_tag(:label, services_label)
            end
          services << notice
        end

      # == Output display
      heading = html_tag(2, heading_label, id: heading_id, class: heading_css)
      output =
        html_div(class: output_css) do
          r_opt   = { class: results_css, 'aria-labelledby': heading_id }
          results = h.text_area_tag(results_id, nil, r_opt)
          errors  =
            html_div(class: 'pair') do
              id      = errors_id
              label   = errors_label
              label   = h.label_tag(id, label, class: 'label')
              display = h.text_area_tag(id, nil, class: errors_css)
              label << display
            end
          diagnostics =
            html_div(class: 'pair') do
              id      = diagnostics_id
              label   = diagnostics_label
              label   = h.label_tag(id, label, class: 'label')
              display = h.text_area_tag(id, nil, class: diagnostics_css)
              label << display
            end
          results << errors << diagnostics
        end

      # == Full container
      prepend_css!(opt, css)
      html_div(opt) do
        query_panel << prompt << status << heading << output
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

  module InstanceMethods

    include BaseDecorator::InstanceMethods, Paths, Methods

    # =========================================================================
    # :section: BaseDecorator::InstanceMethods overrides
    # =========================================================================

    public

    # options
    #
    # @return [Entry::Options]
    #
    def options
      context[:options] || Entry::Options.new
    end

  end

  module ClassMethods
    include BaseDecorator::ClassMethods, Paths, Methods
  end

  # Cause definitions to be included here and in the associated collection
  # decorator via BaseCollectionDecorator#collection_of.
  #
  module Common
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end
  end

  include Common

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
  # == Usage Notes
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
    html_div('', class: UPLOAD[:preview])
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  EMMA_DATA_FIELDS =
    model_database_fields[:emma_data]&.select { |_, v| v.is_a?(Hash) } || {}

  # Render the contents of the :file_data field.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @see #render_json_data
  #
  def render_file_data(**opt)
    data = object.try(:file_data) || object.try(:[], :file_data)
    render_json_data(data, **opt, field_root: :file_data)
  end

  # Render the contents of the :emma_data field in the same order of EMMA data
  # fields as defined for search results.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @see #render_json_data
  #
  def render_emma_data(**opt)
    data  = object.try(:emma_data) || object.try(:[], :emma_data)
    pairs = json_parse(data).presence
    pairs &&=
      EMMA_DATA_FIELDS.map { |field, config|
        value = pairs.delete(config[:label]) || pairs.delete(field)
        [field, value] unless value.nil?
      }.compact.to_h.merge(pairs)
    render_json_data(pairs, **opt)
  end

  # Render hierarchical data.
  #
  # @param [String, Hash, nil] value
  # @param [Hash]              opt        Passed to #render_field_values
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If *value* was not valid JSON.
  #
  def render_json_data(value, **opt)
    value &&= json_parse(value) unless value.is_a?(Hash)
    html_div(class: 'data-list') do
      if value.present?
        root = opt[:field_root]
        opt[:no_format] ||= :dc_description
        # noinspection RubyNilAnalysis
        pairs =
          value.map { |k, v|
            if v.is_a?(Hash)
              sub_opt = root ? opt.merge(field_root: [root, k.to_sym]) : opt
              v = render_json_data(v, **sub_opt)
            end
            [k, v]
          }.to_h
        render_field_values(pairs: pairs, **opt)
      else
        render_empty_value(EMPTY_VALUE)
      end
    end
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Any]       value
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

  # Render item attributes.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to super except:
  #
  # @option opt [String, Symbol, Array<String,Symbol>] :columns
  # @option opt [String, Regexp, Array<String,Regexp>] :filter
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #model_field_values
  #
  def details(pairs: nil, **opt)
    fv_opt      = extract_hash!(opt, :columns, :filter)
    opt[:pairs] = model_field_values(**fv_opt).merge!(pairs || {})
    super(**opt)
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to super.
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
      control_icon_buttons
    end
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
    entry = Entry.latest_for_sid(item, no_raise: true)
    return unless entry && can?(:modify, entry)
    ctx = { context: opt.delete(:context) }
    dec = new(entry, context: ctx)
    dec.control_icon_buttons(id: entry.id, **opt)
  end

  # ===========================================================================
  # :section: BaseDecorator::Links overrides
  # ===========================================================================

  protected

  # Produce an action icon based on either :path or :id.
  #
  # @param [Symbol] action                One of #CONTROL_ICONS.keys.
  # @param [Hash]   opt                   To LinkHelper#make_link except for:
  #
  # @option opt [String, Proc]  :path
  # @option opt [String]        :icon
  # @option opt [String]        :tip
  # @option opt [Boolean, Proc] :enabled
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML link element.
  # @return [nil]                         If *item* unrelated to a submission.
  #
  def control_icon_button(action, **opt)
    return super unless action == :check
    # noinspection RubyMismatchedArgumentType
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
  # @param [Hash]            opt      To PopupHelper#inline_popup except:
  #
  # @option opt [Hash] :attr          Options for deferred content.
  # @option opt [Hash] :placeholder   Options for transient placeholder.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/shared/modal-base.js *ModalBase.toggleModal()*
  #
  def check_status_popup(path, id:, **opt)
    css    = '.check-status-popup'
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

  protected

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
  # @return [Hash{Symbol=>Any}]
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
  # @param [Hash] opt                 Passed to #html_div for outer *div*.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LayoutHelper::SearchBar#search_input
  # @see LayoutHelper::SearchBar#search_button_label
  # @see file:javascripts/feature/model-form.js *monitorSourceRepository()*
  #
  def parent_entry_select(**opt)
    css    = '.parent-entry-select'
    id     = 'parent-entry-search'
    b_opt  = { role: 'button', tabindex: 0 }

    # Directions.
    t_id   = opt[:'aria-labelledby'] = "#{id}-title"
    title  =
      'Please indicate the EMMA entry for the original repository item. ' \
      'If possible, enter the standard identifier (ISBN, ISSN, OCLC, etc.) ' \
      'or the full title of the original work.' # TODO: I18n
    title  = html_div(title, id: t_id, class: 'search-title')

    # Text input.
    ctrlr  = :search
    input  = h.search_input(id, ctrlr)

    # Submit button.
    submit = h.search_button_label(ctrlr)
    submit = html_div(submit, b_opt.merge(class: 'search-button'))

    # Cancel button.
    cancel = 'Cancel' # TODO: I18n
    cancel = html_div(cancel, b_opt.merge(class: 'search-cancel'))

    prepend_css!(opt, css, 'hidden')
    html_div(opt) do
      title << input << submit << cancel
    end
  end

  # ===========================================================================
  # :section: BaseDecorator::Menu overrides
  # ===========================================================================

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

  # ===========================================================================
  # :section: BaseDecorator overrides
  # ===========================================================================

  public

  # Client-side scripting which are supplied via 'assets:precompile'.
  #
  # @param [Hash{Symbol=>Any}]
  #
  # @see file:app/assets/javascripts/shared/assets.js.erb  *Emma.Entry*
  #
  def self.js_properties
    path_properties = {
      renew:        renew_path,
      reedit:       reedit_path,
      check:        check_path(id: JS_ID),
      cancel:       cancel_path,
      endpoint:     endpoint_path,
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
