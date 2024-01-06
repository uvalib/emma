# app/decorators/manifest_item_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/manifest_item" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [ManifestItem]
#
class ManifestItemDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for ManifestItem

  # ===========================================================================
  # :section: Definitions shared with ManifestItemsDecorator
  # ===========================================================================

  public

  module SharedPathMethods

    include BaseDecorator::SharedPathMethods

    # =========================================================================
    # :section: BaseDecorator::SharedPathMethods overrides
    # =========================================================================

    public

    def show_select_path(*)
      not_applicable
    end

    def edit_select_path(*)
      not_applicable
    end

    def delete_select_path(*)
      not_applicable
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def upload_path(*, **opt)
      h.manifest_item_upload_path(**opt)
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

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # manifest_for
    #
    # @param [String,Model,Hash,Array,nil] item
    # @param [Hash]                        opt
    #
    # @return [String, nil]
    #
    #--
    # noinspection RailsParamDefResolve
    #++
    def manifest_for(item = nil, **opt)
      return opt[:manifest] if opt[:manifest]
      return item.id        if item.is_a?(Manifest)
      (item || try(:object))&.try(:manifest_id)
    end

    # =========================================================================
    # :section: BaseDecorator::SharedPathMethods overrides
    # =========================================================================

    protected

    # path_for
    #
    # @param [Model,Hash,Array,nil] item
    # @param [Hash]                 opt
    #
    # @return [String]
    #
    def path_for(item = nil, **opt)
      opt[:manifest] ||= manifest_for(item)
      super
    end

  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  #--
  # noinspection RubyTooManyMethodsInspection
  #++
  module SharedGenericMethods

    include BaseDecorator::SharedGenericMethods
    include BaseDecorator::Form
    include BaseDecorator::Grid
    include BaseDecorator::Lookup

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Bulk grid configuration values.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    BULK_GRID_CFG = I18n.t('emma.bulk.grid', default: {}).deep_freeze

    # @private
    # @type [Hash{Symbol=>Hash}]
    FILE_TYPE_CFG = BULK_GRID_CFG[:file]

    # @private
    # @type [Array<Symbol>]
    FILE_TYPES = FILE_TYPE_CFG.keys.freeze

    # =========================================================================
    # :section: BaseDecorator::Configuration overrides
    # =========================================================================

    public

    # Get all configured record fields for the model.
    #
    # @return [ActionConfig]
    #
    def model_form_fields(**)
      json_fields, db_fields = partition_hash(super, :file_data, :emma_data)
      emma_data = json_fields[:emma_data]&.slice(*EMMA_DATA_FIELDS)
      db_fields.merge!(emma_data) if emma_data.present?
      ActionConfig.wrap(db_fields)
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
    ICONS = BULK_GRID_CFG[:icons]

    # Icon definitions for this decorator.
    #
    # @return [Hash{Symbol=>Hash{Symbol=>*}}]
    #
    def icon_definitions
      ICONS
    end

    # control_icon_button
    #
    # @param [Symbol]             action    One of #icon_definitions.keys.
    # @param [GridIndex, Integer] index
    # @param [String]             unique
    # @param [Hash]               opt       Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    def control_icon_button(action, index: nil, unique: nil, **opt)
      id_parts = opt[:id] || ['control', action, opt[:row]]
      opt[:id] = unique_id(*id_parts, index: index, unique: unique)
      opt[:'aria-labelledby'] = l_id = "label-#{opt[:id]}"

      if action == :lookup
        button = lookup_control(ACTION_ATTR => action, button: opt) or return
      else
        button = super(action, **opt) or return
      end

      label = action.to_s.titlecase # TODO: cfg lookup
      label = html_span(label, id: l_id, class: 'label')

      button << label
    end

    # =========================================================================
    # :section: BaseDecorator::Lookup overrides
    # =========================================================================

    public

    # Bibliographic lookup control which engages #lookup_modal.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def lookup_control(**opt)
      opt[:type] ||= :icon
      super
    end

    # =========================================================================
    # :section: BaseDecorator::Lookup overrides
    # =========================================================================

    protected

    # The options to create a toggle button to activate the bibliographic
    # lookup popup.
    #
    # @param [Hash] opt
    #
    # @option opt [Hash] :label       Override the default button label.
    #
    # @return [Hash]
    #
    def lookup_button_options(**opt)
      opt[:label] ||= symbol_icon(:lookup)
      super
    end

    # =========================================================================
    # :section: BaseDecorator::List overrides
    # =========================================================================

    public

    # Render a single entry for use within a list of items.
    #
    # @param [Hash] opt                 Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def list_item(**opt)
      trace_attrs!(opt)
      index = opt[:index]
      outer = opt[:outer] = opt[:outer]&.dup || {}
      outer[:id]                ||= "#{model_type}-item-#{index}" if index
      outer[:'data-item-id']    ||= object.id
      outer[:'data-item-row']   ||= object.row
      outer[:'data-item-delta'] ||= object.delta
      super
    end

    # Include control icons below the entry number.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def list_item_number(**opt)
      trace_attrs!(opt)
      super(**opt) do
        control_icon_buttons(**opt.slice(:index))
      end
    end

    # Don't display an item number in manifest listings.
    #
    # @return [nil]
    #
    def list_item_number_label(**)
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
      super(%i[new edit upload])
    end

    # This is a variation for ensuring that the `<div>` enclosing the checkbox
    # list element is not given `role='group'`.
    #
    # @param [String] name
    # @param [Array]  value
    # @param [Class]  range
    # @param [Hash]   opt               Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def render_form_menu_multi(name, value, range:, **opt)
      opt[:outer] = { role: nil }.merge!(opt[:outer] || {})
      super
    end

    # =========================================================================
    # :section: BaseDecorator::Row overrides
    # =========================================================================

    public

    SKIPPED_FIELDS = ManifestItem::NO_SHOW_COLS

    # The fields which are displayed in the expandable "Item Details" panel.
    #
    # @param [Array<Symbol>]
    #
    DETAILS_FIELDS = %i[
      field_error
      updated_at
      last_saved
      last_submit
    ].freeze

    HIDDEN_FIELDS = [*ManifestItem::STATUS_COLUMNS, *DETAILS_FIELDS].freeze

    UNDISPLAYED_FIELDS = [
      (:repository unless ManifestItem::ALLOW_NIL_REPOSITORY)
    ].compact.freeze

    # The names of ManifestItem columns that are not rendered.
    #
    # @return [Array<Symbol>]
    #
    def row_skipped_columns
      super + SKIPPED_FIELDS
    end

    # =========================================================================
    # :section: BaseDecorator::Grid overrides
    # =========================================================================

    public

    # The names of each grid data column which is not rendered.
    #
    # @return [Array<Symbol>]
    #
    def grid_row_skipped_columns
      super + HIDDEN_FIELDS
    end

    # The names of each grid data column which is rendered but not visible.
    #
    # @return [Array<Symbol>]
    #
    def grid_row_undisplayed_columns
      super + UNDISPLAYED_FIELDS
    end

    # Show a button for expanding/contracting the controls column in the top
    # left grid cell.
    #
    # @param [String] css               Characteristic CSS class/selector.
    # @param [Hash]   opt
    #
    # @return [Array<ActiveSupport::SafeBuffer>]
    #
    def grid_head_control_headers(css: CONTROLS_CELL_CLASS, **opt)
      h_opt  = append_css(opt, 'hidden').except(:tag, :css, :'aria-colindex')
      hidden =
        HIDDEN_FIELDS.map do |f|
          grid_head_cell(nil, **h_opt, prop: field_configuration(f))
        end
      idx  = opt[:'aria-colindex'] ||= 1
      l_id = opt[:'aria-labelledby'] = unique_id(css, index: idx)
      super do
        control_group(l_id) do
          [column_expander, header_expander, *hidden]
        end
      end
    end

    # Render a grid header cell.
    #
    # @param [Symbol, nil] col        Data column.
    # @param [Hash]        opt        Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @yield Leading content
    # @yieldreturn [String, Array]
    #
    def grid_head_cell(col, **opt, &blk)
      return super if col.nil?
      idx  = opt[:'aria-colindex']
      l_id = opt[:'aria-labelledby'] = unique_id(*opt[:css], index: idx)
      prop = opt[:prop] ||= field_configuration(col)
      # noinspection RailsParamDefResolve
      unless prop[:pairs] || (pairs = prop[:type].try(:pairs)).blank?
        prop = prop.merge(pairs: pairs)
        opt[:prop] = opt[:prop].merge(pairs: pairs.to_json)
      end
      if prop[:required]
        opt[:label] =
          grid_head_label(css: 'label', id: l_id) do
            t_opt = { class: 'text' }
            text  = opt[:label] || prop&.dig(:label) || col.to_s
            text  = html_span(text, **t_opt) unless text.html_safe?
            n_opt = { class: 'required' }
            n_opt[:'aria-label'] = note = 'required' # TODO: I18n
            n_opt[:title] = "(#{note})"
            note  = html_span('*', **n_opt)
            text << note
          end
      end
      parts = Array.wrap((yield if block_given?))
      super(col, **opt) do
        # noinspection RubyMismatchedArgumentType
        control_group(l_id) do
          parts << field_details(col, prop)
          parts << type_details(col, prop)
        end
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Generate a <detail> element describing a field.
    #
    # @param [Symbol]           col
    # @param [FieldConfig, nil] prop
    # @param [Proc]             blk   Passed to #html_details
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def field_details(col, prop = nil, &blk)
      prop ||= field_configuration(col)
      tag    = 'field' # TODO: I18n
      name   = prop[:field] || col
      req    = ('required' if prop[:required]) # TODO: I18n

      tag    = html_span("#{tag}: ", class: 'tag')
      name   = html_span(name, class: 'field-name')
      req    = html_tag(:em, " (#{req})") if req

      first  = safe_join([tag, name, req].compact)
      lines  = prop[:notes_html] || prop[:notes]
      html_details(first, *lines, &blk)
    end

    # Generate a <detail> element describing a type.
    #
    # @param [Symbol]           col
    # @param [FieldConfig, nil] prop
    # @param [Proc]             blk   Passed to #html_details
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def type_details(col, prop = nil, &blk)
      prop ||= field_configuration(col)
      tag    = 'type' # TODO: I18n
      many   = prop[:array].presence
      type   = prop[:type]&.to_s || 'string'
      # noinspection SpellCheckingInspection
      case type
        when /^text/     then name = 'string'
        when 'date'      then name = "#{type} [YYYYMMDD]"
        when 'TrueFalse' then name = 'TRUE or FALSE value'
        when /^[A-Z]/    then name = "#{type} value".pluralize(many || 1) # TODO: I18n
        else                  name = type
      end

      tag    = html_span("#{tag}: ", class: 'tag')
      many   = 'one or more ' if many # TODO: I18n
      name   = html_span(name, class: 'type-name')
      first  = safe_join([tag, many, name].compact)
      lines  =
        if prop[:pairs]
          label_dt = 'Data value'   # TODO: I18n
          label_dd = 'Displayed as' # TODO: I18n
          html_tag(:dl) do
            opt = { class: 'label' } # First pair only
            { label_dt => label_dd }.merge!(prop[:pairs]).map do |value, label|
              value = html_tag(:dt, value, **opt)
              label = html_tag(:dd, label, **opt)
              opt   = {}
              value << label
            end
          end
        else
          "Description of #{type.inspect} to come..." # TODO: ...
        end
      html_details(first, *lines, &blk)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # A button for expanding/contracting the controls column.
    #
    # @param [String] css             Characteristic CSS class/selector.
    # @param [Hash]   opt             Passed to #grid_control
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see file:javascripts/controllers/manifest-edit.js *toggleControlsColumn*
    #
    def column_expander(css: '.column-expander', **opt)
      grid_control(:column, css: css, **opt)
    end

    # A button for expanding/contracting the head row.
    #
    # @param [String] css             Characteristic CSS class/selector.
    # @param [Hash]   opt             Passed to #grid_control
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see file:javascripts/controllers/manifest-edit.js *toggleHeaderRow*
    #
    def header_expander(css: '.row-expander', **opt)
      grid_control(:row, css: css, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Column/header expand/contract controls.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    GRID_HEADER = BULK_GRID_CFG[:headers]

    # A button for controlling overall grid behavior.
    #
    # @param [Symbol]  type           Either :column or :row.
    # @param [Boolean] expanded       If *true* start expanded.
    # @param [String]  css            Characteristic CSS class/selector.
    # @param [Hash]    opt            Passed to #html_button except:
    #
    # @option opt [String] :label     Override default label.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # === Implementation Notes
    #
    def grid_control(type, expanded: false, css: '.grid-control', **opt)
      type_cfg  = GRID_HEADER[type] || {}
      state_cfg = expanded ? type_cfg[:closer] : type_cfg[:opener]
      label     = opt.delete(:label) || state_cfg[:label] || type_cfg[:label]
      opt[:title] ||= state_cfg[:tooltip] || type_cfg[:tooltip]
      prepend_css!(opt, 'expanded') if expanded
      prepend_css!(opt, css)
      html_button(label, **opt)
    end

    # =========================================================================
    # :section: Manifest submission
    # =========================================================================

    public

    # Submission status type keys and column labels.
    #
    # (The steps associated with the unique labels of #SUBMIT_STEPS_TABLE.)
    #
    # @type [Hash{Symbol=>Hash}]
    #
    SUBMIT_STEPS =
      SubmissionService::Properties::SUBMIT_STEPS_TABLE
        .select { |_, entry| entry[:client] || entry[:server] }
        .uniq   { |_, entry| entry[:label] }.to_h
        .freeze

    # Submission status grid column names.
    #
    # @type [Array<Symbol>]
    #
    SUBMIT_COLUMNS = [:controls, :item_name, *SUBMIT_STEPS.keys].freeze

    # Submission status value CSS classes and labels.
    #
    # @type [Hash{Symbol=>Hash{Symbol=>String}}]
    #
    SUBMIT_STATUS = BULK_GRID_CFG.dig(:status, :value)

    # Mapping of submission status CSS class on to label.
    #
    # @type [Hash{String=>String}]
    #
    SUBMIT_STATUS_LABELS =
      SUBMIT_STATUS.map { |_, entry| [entry[:css], entry[:label]] }.to_h.freeze

    S_OK           = :ok
    S_BLANK        = :blank
    S_UNSAVED      = :unsaved
    S_DATA_MISSING = :data_missing
    S_FILE_MISSING = :file_missing
    S_FILE_NEEDED  = :file_needed

    # Statuses whose displays show an Edit button.
    #
    # @type [Array<Symbol>]
    #
    STATUS_SHOW_EDIT =
      [S_UNSAVED, S_FILE_NEEDED, S_FILE_MISSING, S_DATA_MISSING].freeze

    # Statuses whose label is a <details> instead of a <div>.
    #
    # @type [Array<Symbol>]
    #
    STATUS_SHOW_DETAILS = [S_FILE_NEEDED].freeze

    # =========================================================================
    # :section: Manifest submission
    # =========================================================================

    public

    # The row number of the grid header.
    #
    # @type [Integer]
    #
    HEADER_ROW = 1

    # The header row of the submission status grid.
    #
    # @param [Integer] row
    # @param [String]  css
    # @param [Hash]    opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see #submit_status_element
    #
    def submission_status_header(row: HEADER_ROW, css: '.head', **opt)
      ctrl = nil
      name = 'Item Name' # TODO: I18n
      stat = SUBMIT_STEPS
      prepend_css!(opt, css)
      submit_status_element(ctrl, name, stat, row: row, **opt)
    end

    # =========================================================================
    # :section: Manifest submission
    # =========================================================================

    protected

    # submit_status_element
    #
    # @param [String, nil]          ctrl
    # @param [String, ManifestItem] item
    # @param [Hash{Symbol=>*}]      statuses
    # @param [Integer]              row
    # @param [Integer]              col
    # @param [Symbol]               tag       Default: :tr.
    # @param [String]               css
    # @param [Hash]                 opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def submit_status_element(
      ctrl,
      item,
      statuses,
      row:      HEADER_ROW,
      col:      0,
      tag:      nil,
      css:      '.submission-status',
      **opt
    )
      table   = for_html_table?(tag)
      tag     = :tr if table
      heading = (row == HEADER_ROW)
      col_opt = opt.slice(:'data-number').merge!(col: col)
      col_opt.merge!(role: 'columnheader') if table && heading

      # Item selection column.
      col_opt[:col] += 1
      ctrl = submit_status_ctls(ctrl, **col_opt) unless ctrl&.html_safe?

      # Item name column.
      col_opt[:col] += 1
      item = submit_status_item(item, **col_opt) unless item&.html_safe?

      # Status value columns.
      col_opt[:row] = row.pred unless heading
      values =
        statuses.map do |type, stat|
          col_opt[:col] += 1
          stat = S_OK        if stat.is_a?(TrueClass)
          stat = S_BLANK     if stat.is_a?(FalseClass) || stat.nil?
          stat = stat.to_sym if stat.is_a?(String)
          col_opt[:label] = (stat[:label] if stat.is_a?(Hash))
          # noinspection RubyMismatchedArgumentType
          submit_status_value(type, stat, **col_opt)
        end

      opt[:'aria-rowindex'] = row
      opt[:role]            = 'row' if table
      opt[:separator]       = ''    unless opt.key?(:separator)
      prepend_css!(opt, css)
      html_tag(tag, ctrl, item, *values, **opt)
    end

    # submit_status_ctls
    #
    # @param [String, nil]  ctrl
    # @param [Integer, nil] col
    # @param [Symbol]       tag
    # @param [String]       css
    # @param [Hash]         opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def submit_status_ctls(ctrl = nil, col: nil, tag: nil, css: '.controls', **opt)
      table = for_html_table?(tag)
      head  = opt[:role].to_s.include?('header')
      tag   = head ? :th : :td if table
      base  = opt.delete(:base)

      if !ctrl
        base ||= unique_id(css)
        cb_id  = "checkbox-#{base}"
        lbl_id = "label-#{base}"
        number = opt[:'data-number']
        label  = "Select item #{number} for submission".squeeze # TODO: I18n
        label  = h.label_tag(cb_id, label, id: lbl_id)
        cb     = h.check_box_tag(cb_id)
        ctrl   = control_group(lbl_id) { cb << label }
      elsif !ctrl.html_safe?
        ctrl   = html_div(ctrl, class: 'text')
      end

      opt[:role] ||= grid_cell_role if table
      opt[:'aria-colindex'] = col   if col
      prepend_css!(opt, css)
      html_tag(tag, ctrl, **opt)
    end

    # submit_status_item
    #
    # @param [String, ManifestItem] item
    # @param [Integer, nil]         col
    # @param [Symbol]               tag
    # @param [String]               css
    # @param [Hash]                 opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def submit_status_item(item, col: nil, tag: nil, css: '.item-name', **opt)
      table = for_html_table?(tag)
      head  = opt[:role].to_s.include?('header')
      tag   = head ? :th : :td if table
      base  = opt.delete(:base)
      if item.is_a?(ManifestItem)
        part = {
          identifier: :dc_identifier,
          title:      :dc_title,
          author:     :dc_creator,
        }.transform_values! { |field|
          item[field].to_s.split("\n").map! { |s|
            s.strip.delete_suffix(';')
          }.compact_blank!.presence
        }.compact_blank!
        sep   = ' / '
        first = [*part[:title], *part[:author], *part[:identifier]].take(2)
        first = first.join(sep)
        uniq  = hex_rand
        r_opt = { index: uniq, separator: sep, no_fmt: true, no_help: true }
        lines = part.map { |k, v| render_pair(k.capitalize, v, **r_opt) } # TODO: I18n
        l_id  = 'label-%s' % (base || unique_id(css))
        item  = html_details(first, *lines, class: 'text', id: l_id)
        item  = control_group(l_id) { item }
      else
        item  = html_div(item, class: 'text') unless item&.html_safe?
      end
      opt[:role] ||= grid_cell_role if table
      opt[:'aria-colindex'] = col   if col
      prepend_css!(opt, css)
      html_tag(tag, item, **opt)
    end

    # submit_status_value
    #
    # @param [Symbol]       type
    # @param [Symbol, nil]  status
    # @param [Integer, nil] col
    # @param [Integer, nil] row
    # @param [Symbol]       tag
    # @param [String]       css
    # @param [Hash]         opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def submit_status_value(type, status, col:, row: nil, tag: nil, css: '.status', **opt)
      table  = for_html_table?(tag)
      head   = opt[:role].to_s.include?('header') || !respond_to?(:object)
      tag    = head ? :th : :td if table
      label  = opt.delete(:label)
      base   = opt.delete(:base) || unique_id(css)
      lbl_id = "label-#{base}"

      text   = submit_status_text(type, status, label: label, id: lbl_id)
      button = (submit_status_link(type, status, row: row) unless head)

      opt[:role] ||= grid_cell_role if table
      opt[:'aria-colindex'] = col   if col
      step_css  = SUBMIT_STEPS.dig(type, :css)
      value_css = SUBMIT_STATUS.dig(status, :css)
      prepend_css!(opt, css, step_css, value_css)
      html_tag(tag, **opt) do
        control_group(lbl_id) { [text, button] }
      end
    end

    # The text on the status element.
    #
    # @param [Symbol]      type
    # @param [Symbol, nil] status
    # @param [String]      css
    # @param [Hash]        opt
    #
    # @option opt [String] :label
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def submit_status_text(type, status, css: '.text', **opt)
      prepend_css!(opt, css)
      details = STATUS_SHOW_DETAILS.include?(status)
      lbl_id  = opt.delete(:id)
      label   = opt[:label]
      label ||= SUBMIT_STATUS.dig(status, :label)
      label ||= (status || type).to_s.titleize

      # Simple label.
      p_opt   = !details ? opt : append_css(opt, 'hidden')
      plain   = html_div(label, **p_opt, id: lbl_id)

      # Expandable label.
      d_opt   = details ? opt : append_css(opt, 'hidden')
      details = html_tag(:summary, label) << html_div(class: 'name')
      details = html_tag(:details, details, **d_opt)

      plain << details
    end

    # Control for fixing a condition resulting in a given status.
    #
    # @param [Symbol]       _type
    # @param [Symbol, nil]  status
    # @param [Integer, nil] row
    # @param [String]       css
    # @param [Hash]         opt
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    # @see file:javascripts/controllers/manifest-edit.js *scrollToCenter()*
    #
    def submit_status_link(_type, status, row: nil, css: '.fix', **opt)
      label = 'Edit' # TODO: I18n
      path  = edit_row_path(row)
      opt[:title] ||= 'Modify this manifest item' # TODO: I18n
      prepend_css!(opt, css)
      append_css!(opt, 'hidden') unless STATUS_SHOW_EDIT.include?(status)
      make_link(label, path, **opt, 'data-turbolinks': false)
    end

    # The URL path to the edit page scrolled to the indicated row.
    #
    # @param [Integer, nil] row
    # @param [Hash]         opt       Options for #edit_manifest_path.
    #
    # @return [String]
    #
    def edit_row_path(row, **opt)
      row  = positive(row)
      page = row && positive((row - 1) / grid_page_size)
      opt[:id]     ||= object.manifest_id
      opt[:page]   ||= page + 1                    if page
      opt[:anchor] ||= "#{model_type}-item-#{row}" if row
      h.edit_manifest_path(**opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # A set of status indicator icons and descriptive labels.
    #
    # @param [ManifestItem] item
    # @param [Integer]      row
    # @param [String]       unique
    # @param [String]       css       Characteristic CSS class/selector.
    # @param [Hash]         opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see file:assets/javascripts/controllers/manifest-edit.js *statusData()*
    #
    def row_indicators(item, row: nil, unique: nil, css: '.indicators', **opt)
      index    = opt.delete(:index)
      unique ||= index || hex_rand
      id_base  = [row, unique].compact.join('-')
      prepend_css!(opt, css)
      html_div(**opt) do
        ManifestItem::STATUS.map do |field, prop|
          s_id   = "#{field}-indicator-#{id_base}"
          l_id   = "label-#{s_id}"

          value  = item[field]&.to_sym || :missing
          if (field == :ready_status) && (value == :ready) && item.unsaved?
            value = :unsaved
          end
          s_opt  = { 'data-field': field, id: s_id, 'aria-describedby': l_id }
          status = row_indicator(value, **s_opt)

          text   = prop[value] || value
          l_opt  = { 'data-field': field, id: l_id }
          label  = row_indicator_label(text, **l_opt)

          status << label
        end
      end
    end

    # A collapsible element listing values for ManifestItem fields that are not
    # related to grid columns.
    #
    # @param [ManifestItem] item
    # @param [Integer]      row
    # @param [String]       unique
    # @param [String]       css       Characteristic CSS class/selector.
    # @param [Hash]         opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def row_details(item, row: nil, unique: nil, css: '.details', **opt)
      index   = opt.delete(:index)
      unique ||= index || hex_rand
      id_base = [row, unique].compact.join('-')
      summary = 'Item Details' # TODO: I18n
      content =
        DETAILS_FIELDS.map do |field|
          v_id  = "#{field}-detail-#{id_base}"
          l_id  = "label-#{v_id}"

          v_opt = { 'data-field': field, id: v_id, 'aria-describedby': l_id }
          value = item[field].presence || EMPTY_VALUE
          value = row_detail_value(value, **v_opt)

          l_opt = { 'data-field': field, id: l_id }
          label = field # TODO: cfg lookup
          label = row_detail_value_label(label, **l_opt)

          label << value
        end
      prepend_css!(opt, css)
      html_details(summary, *content, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    LABEL_CLASS = BaseDecorator::List::DEFAULT_LABEL_CLASS
    VALUE_CLASS = BaseDecorator::List::DEFAULT_VALUE_CLASS

    # row_indicator
    #
    # @param [String,Symbol] value
    # @param [String]        css
    # @param [Hash]          opt
    #
    # @option opt [String]        :id                 Required
    # @option opt [String,Symbol] :'data-field'       Required
    # @option opt [String]        :'aria-describedby' Required
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def row_indicator(value, css: ".indicator.#{VALUE_CLASS}", **opt)
      opt[:role] ||= 'status'
      field = opt[:'data-field']
      append_css!(opt, field, css, "value-#{value}")
      html_div(**opt)
    end

    # row_indicator_label
    #
    # @param [String,Symbol] label
    # @param [String]        css
    # @param [Hash]          opt
    #
    # @option opt [String]   :id      Required
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def row_indicator_label(label, css: LABEL_CLASS, **opt)
      label = label.to_s.strip
      label << '.' unless label.match?(/[[:punct:]]$/)
      append_css!(opt, css)
      html_div(label, **opt)
    end

    # row_detail_value_label
    #
    # @param [String,Symbol] label
    # @param [String]        css
    # @param [Hash]          opt
    #
    # @option opt [String]   :id      Required
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def row_detail_value_label(label, css: LABEL_CLASS, **opt)
      append_css!(opt, css)
      html_div(label, **opt)
    end

    # row_detail_value
    #
    # @param [Hash,Array,String,nil] value
    # @param [String]                css
    # @param [Hash]                  opt
    #
    # @option opt [String]        :id                 Required
    # @option opt [String,Symbol] :'data-field'       Required
    # @option opt [String]        :'aria-describedby' Required
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def row_detail_value(value, css: VALUE_CLASS, **opt)
      # noinspection RubyMismatchedArgumentType
      value = row_field_error_details(value, **opt) if value.is_a?(Hash)
      opt[:separator] = HTML_BREAK unless opt.key?(:separator)
      append_css!(opt, css)
      html_div(value, **opt)
    end

    # row_field_error_details
    #
    # @param [Hash]   value
    # @param [String] css
    # @param [Hash]   opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see file:javascripts/controllers/manifest-edit.js *updateRowDetails*
    #
    def row_field_error_details(value, css: '.field-errors', **opt)
      append_css!(opt, css)
      html_tag(:dl, **opt) do
        value.map do |fld, errs|
          if errs.is_a?(Hash)
            errs =
              errs.map do |k, v|
                item  = html_span(k, class: 'quoted')
                issue = html_span(v)
                html_div { "#{item}: #{issue}".html_safe }
              end
          elsif errs.is_a?(Array)
            errs = safe_join(errs, HTML_BREAK)
          else
            errs = ERB::Util.h(errs)
          end
          html_tag(:dt, fld) << html_tag(:dd, *errs)
        end
      end
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
    # @return [ManifestItem::Options]
    #
    def options
      context[:options] || ManifestItem::Options.new
    end

    # row_indicators
    #
    # @param [ManifestItem, nil] item   Default: `#object`.
    # @param [Hash]              opt    Passed to super
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def row_indicators(item = nil, **opt)
      item ||= object
      super
    end

    # row_details
    #
    # @param [ManifestItem, nil] item   Default: `#object`.
    # @param [Hash]              opt    Passed to super
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def row_details(item = nil, **opt)
      item ||= object
      super
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

class ManifestItemDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The ID of the Manifest associated with the decorated ManifestItem.
  #
  # @param [String] id                Override the normal value.
  #
  # @return [String]
  #
  def manifest_id(id = nil)
    if id
      @manifest_id = id
    else
      @manifest_id ||= object.manifest.id
    end
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
  def list_field_value(value, field:, **opt)
    if present? && object.field_names.include?(field)
      case (v = object[field])
        when Array    then v.join("\n")
        when BoolType then v.to_s
        else               v || EMPTY_VALUE
      end
    end || super
  end

  # ===========================================================================
  # :section: BaseDecorator::Grid overrides
  # ===========================================================================

  public

  # Generate the interior of the controls grid cell.
  #
  # @param [Array]   added            Optional elements after the buttons.
  # @param [Integer] row              Associated grid row.
  # @param [String]  unique
  # @param [Hash]    opt              Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield Additional content if provided.
  # @yieldreturn [Array,ActiveSupport::SafeBuffer,nil]
  #
  # @see file:javascripts/controllers/manifest-edit.js *toggleControlsColumn*
  #
  def grid_row_control_contents(*added, row: nil, unique: nil, **opt)
    index = opt.delete(:index)
    r_opt = { row: row, unique: (unique || index || hex_rand) }

    added.prepend(row_details(**r_opt), row_indicators(**r_opt))
    added.concat(Array.wrap(yield)) if block_given?

    super(*added, **r_opt, **opt)
  end

  # Render a single grid item.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_item(**opt)
    # noinspection RailsParamDefResolve
    opt[:group]       ||= object.try(:state_group)
    opt[:field_error] ||= object.field_error unless opt[:template]
    super
  end

  # ===========================================================================
  # :section: BaseDecorator::Grid overrides
  # ===========================================================================

  public

  # The CSS class for the element containing feedback elements generated by
  # Uppy plugins.
  #
  # @type [String]
  #
  # @see file:javascripts/shared/uploader.js *MultiUploader.DISPLAY_CLASS*
  #
  UPLOADER_DISPLAY_CLASS = 'uploader-feedback'

  # Render a single label/value pair in a grid cell.
  #
  # @param [String, Symbol, nil] label
  # @param [*]                   value
  # @param [Symbol]              field
  # @param [FieldConfig]         prop
  # @param [Integer, nil]        col
  # @param [Hash]                opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @see file:javascripts/controllers/manifest-edit.js *updateFileUploaderCols*
  #
  def grid_data_cell_render_pair(label, value, field:, prop:, col: nil, **opt)
    if field == :file_data
      value = json_parse(value)
      opt[:'data-value'] = value.to_json if value
      file_name, file_type = value && ManifestItem.file_name_type(value)
      file_type_entries =
        FILE_TYPES.map do |t|
          if t == file_type
            html_div(file_name, class: "from-#{t} active")
          else
            html_div(nil, class: "from-#{t}", 'aria-hidden': true)
          end
        end
      value = safe_join(file_type_entries)
      opt[:value_css] ||= FILE_NAME_CLASS
      opt[:value_css]   = css_classes(opt[:value_css], 'complete') if file_name
      opt[:wrap]        = css_classes(UPLOADER_CLASS, opt[:wrap])
    end
    super
  end

  # The edit element for a grid data cell.
  #
  # @param [Symbol]           field   For 'data-field' attribute.
  # @param [*]                value
  # @param [FieldConfig, nil] prop    Default: from field/model.
  # @param [Hash]             opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def grid_data_cell_edit(field, value, prop, **opt)
    if field == :file_data
      opt[:render] ||= :render_grid_file_input
    end
    super
  end

  # ===========================================================================
  # :section: Grid methods for individual items
  # ===========================================================================

  protected

  FILE_INPUT_TYPES =
    FILE_TYPE_CFG.select { |_, v| v[:panel] && v[:enabled] }.keys.freeze

  PREPEND_CONTROLS_CLASS = 'uppy-FileInput-container-prepend'
  APPEND_CONTROLS_CLASS  = 'uppy-FileInput-container-append'

  # For the :file_data column, display the path to the file if present or an
  # upload button if not.
  #
  # This also generates a hidden container for buttons that can be added
  # client-side to .uppy-FileInput-container after it is created by Uppy.
  #
  # @param [String] _name
  # @param [*]      _value
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:controllers/manifest-edit.js  *initializeAddedControls*
  #
  def render_grid_file_input(_name, _value, css: UPLOADER_DISPLAY_CLASS, **opt)
    prepend_css!(opt, css)
    display  = html_div(**opt)
    controls = FILE_INPUT_TYPES.map { |type| file_input_popup(src: type) }
    controls = html_div(*controls, class: "#{APPEND_CONTROLS_CLASS} hidden")
    controls << display
  end

  # Generate an alternate file input control as a button with a hidden popup.
  #
  # @param [Symbol] src               One of #FILE_INPUT_TYPES.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def file_input_popup(src:, css: '.inline-popup', **opt)
    prop     = FILE_TYPE_CFG[src] || {}
    type     = prop[:type]  || src
    type_css = prop[:class] || "from-#{type}"

    id       = opt.delete(:id) || unique_id(type, index: 0)
    button   = file_input_ctrl(src: src, id: id, **opt)
    panel    = file_input_panel(src: src, id: id, **opt)

    opt.merge!('data-src': src, 'data-type': type)
    prepend_css!(opt, css, type_css)
    html_div(**opt) do
      button << panel
    end
  end

  # Generate a visible button of an alternate file input control.
  #
  # @param [Symbol] src               One of #FILE_INPUT_TYPES.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def file_input_ctrl(src:, css: PopupHelper::POPUP_TOGGLE_CLASS, **opt)
    prop  = FILE_TYPE_CFG[src] || {}
    label = prop[:label]
    prepend_css!(opt, css)
    html_button(label, **opt)
  end

  # Generate a hidden panel to prompt for a file name.
  #
  # @param [String] id                HTML ID of the visible button.
  # @param [Symbol] src               One of #FILE_INPUT_TYPES.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def file_input_panel(id:, src:, css: PopupHelper::POPUP_PANEL_CLASS, **opt)
    prop        = FILE_TYPE_CFG[src] || {}
    panel       = prop[:panel] || {}
    type        = prop[:type]  || src
    type_css    = prop[:class] || "from-#{type}"
    popup_id    = html_id(css, id, underscore: false)

    desc_id     = "label-#{popup_id}"
    desc_opt    = append_css(opt, 'description').merge!(id: desc_id)
    description = html_span(prop[:description], **desc_opt)

    label       = panel[:label]
    name        = html_id(type || label)
    input_id    = html_id('input', id, underscore: false)
    input_opt   = append_css(opt, 'input')
    input_label = h.label_tag(name, label, input_opt.merge(for: input_id))
    input_field = h.text_field_tag(name, nil, input_opt.merge(id: input_id))

    input_submit, input_cancel =
      %i[submit cancel].map do |key|
        b_lbl = panel[key]
        b_opt = append_css(input_opt, "input-#{key}", "#{type_css}-#{key}")
        html_button(b_lbl, **b_opt)
      end

    opt[:'data-id']          = popup_id
    opt[:'aria-describedby'] = desc_id
    prepend_css!(opt, css)
    html_div(**opt) do
      description << input_label << input_field << input_submit << input_cancel
    end
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
  # :section: Manifest submission
  # ===========================================================================

  public

  # Submission status row for a single active submission.
  #
  # @param [Integer, nil] row
  # @param [Integer]      col
  # @param [Integer, nil] index
  # @param [Hash]         opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #submit_status_element
  #
  def submission_status(row: nil, col: 1, index: nil, **opt)
    opt[:'data-number']    ||= index&.succ
    opt[:'data-item-id']   ||= object.id
    opt[:'data-manifest']  ||= object.manifest_id
    opt[:'data-file-name'] ||= object.pending_file_name
    opt[:'data-file-url']  ||= object.pending_file_url

    ctrl = submit_status_ctls(col: col, **opt.slice(:tag, :'data-number'))

    stat = SUBMIT_STEPS.transform_values { nil }
    stat[:entry]  = object.submitted?
    stat[:index]  = object.in_index?
    stat[:upload] = object.file_uploaded?
    stat[:file]   = stat[:upload]   || object.file_literal?
    stat[:file] ||= object.file_ok?  ? S_FILE_NEEDED : S_FILE_MISSING
    stat[:data]   = object.unsaved? && S_UNSAVED
    stat[:data] ||= object.data_ok? || S_DATA_MISSING

    submit_status_element(ctrl, object, stat, row: row, **opt)
  end

  # ===========================================================================
  # :section: BaseDecorator overrides
  # ===========================================================================

  public

  # Client-side scripting which are supplied via 'assets:precompile'.
  #
  # @param [Hash{Symbol=>*}]
  #
  # @see file:app/assets/javascripts/shared/assets.js.erb  *Emma.ManifestItem*
  #
  def self.js_properties
    path_properties = {
      upload: upload_path,
    }
    super.deep_merge!(Path: path_properties, Label: ManifestItem::STATUS)
  end

end

__loading_end(__FILE__)
