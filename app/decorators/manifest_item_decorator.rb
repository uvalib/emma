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

    def edit_select_path(*)
      # NOTE: not applicable to this model
    end

    def delete_select_path(*)
      # NOTE: not applicable to this model
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
      opt[:id] = id_for(item, **opt)
      path_for(item, **opt, action: :bulk_delete)
    end

    def bulk_destroy_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
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
    # @return [Hash{Symbol=>Hash}]
    #
    def model_form_fields(**)
      other, db_fields = partition_hash(super, :file_data, :emma_data)
      emma_data = other[:emma_data]&.except(*Field::PROPERTY_KEYS) || {}
      emma_data.select! { |_, v| v.is_a?(Hash) }
      db_fields.merge!(emma_data)
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

    # Control icon definitions.
    #
    # @return [Hash{Symbol=>Hash{Symbol=>*}}]
    #
    def control_icons
      super(icons: ICONS)
    end

    # control_icon_button
    #
    # @param [Symbol]             action    One of #ICONS.keys.
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

      label  = action.to_s.titlecase # TODO: cfg lookup
      label  = html_tag(:label, label, id: l_id)

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
      opt[:label] ||= ICONS.dig(:lookup, :icon)
      super
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
      outer, tag, index = opt.values_at(:outer, :tag, :index)
      outer = outer&.dup || {}
      outer.reverse_merge!(
        'data-item-id':    object.id,
        'data-item-row':   object.row,
        'data-item-delta': object.delta,
      )
      outer[:id] ||= "#{model_type}-item-#{index}" if index
      if tag.nil? || !TABLE_TAGS.include?(tag)
        outer_classes = outer[:class] ? css_class_array(*outer[:class]) : []
        if outer_classes.none? { |c| c.start_with?('columns-') }
          append_css!(outer, "columns-#{opt[:pairs].size}")
        end
      end
      opt[:outer] = outer unless outer.blank?
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

    # =========================================================================
    # :section: BaseDecorator::Row overrides
    # =========================================================================

    public

    SKIPPED_FIELDS = [
      *ManifestItem::ID_COLS,
      *ManifestItem::GRID_COLS,
      *ManifestItem::TRANSIENT_COLS,
    ].freeze

    DETAILS_FIELDS = %i[
      created_at
      updated_at
      last_saved
      last_lookup
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
    # @param [Hash] opt
    #
    # @return [Array<ActiveSupport::SafeBuffer>]
    #
    def grid_head_control_headers(**opt)
      h_opt  = append_css(opt, 'hidden').except(:tag, :css, :'aria-colindex')
      hidden =
        HIDDEN_FIELDS.map do |col|
          cell_opt = h_opt.merge(config: field_configuration(col))
          grid_head_cell(nil, **cell_opt)
        end
      super { [column_expander, header_expander, *hidden] }
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
    def grid_head_cell(col, **opt, &block)
      return super if col.nil?
      parts  = Array.wrap((yield if block_given?))
      config = opt[:config] ||= field_configuration(col)
      # noinspection RailsParamDefResolve
      unless config[:pairs] || (pairs = config[:type].try(:pairs)).blank?
        config = config.merge(pairs: pairs)
        opt[:config] = opt[:config].merge(pairs: pairs.to_json)
      end
      # noinspection RubyMismatchedArgumentType
      super(col, **opt) do
        parts << field_details(col, config)
        parts << type_details(col, config)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Generate a <detail> element describing a field.
    #
    # @param [Symbol]    col
    # @param [Hash, nil] cfg
    # @param [Proc]      block        Passed to #html_details
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def field_details(col, cfg = nil, &block)
      cfg ||= field_configuration(col)
      tag   = 'field' # TODO: I18n
      name  = cfg[:field] || col
      req   = ('required' if cfg[:required]) # TODO: I18n

      tag   = html_span("#{tag}: ", class: 'tag')
      name  = html_span(name, class: 'field-name')
      req   = html_tag(:em, " (#{req})") if req

      first = safe_join([tag, name, req].compact)
      lines = cfg[:notes_html] || cfg[:notes]
      html_details(first, *lines, &block)
    end

    # Generate a <detail> element describing a type.
    #
    # @param [Symbol]    col
    # @param [Hash, nil] cfg
    # @param [Proc]      block        Passed to #html_details
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def type_details(col, cfg = nil, &block)
      cfg ||= field_configuration(col)
      tag   = 'type' # TODO: I18n
      many  = cfg[:array].presence
      type  = cfg[:type]&.to_s || 'string'
      # noinspection SpellCheckingInspection
      case type
        when /^text/     then name = 'string'
        when 'date'      then name = "#{type} [YYYYMMDD]"
        when 'TrueFalse' then name = 'TRUE or FALSE value'
        when /^[A-Z]/    then name = "#{type} value".pluralize(many || 1) # TODO: I18n
        else                  name = type
      end
      many  = 'one or more ' if many # TODO: I18n

      tag   = html_span("#{tag}: ", class: 'tag')
      many  = "#{many} " if many
      name  = html_span(name, class: 'type-name')
      first = safe_join([tag, many, name].compact)
      lines =
        if cfg[:pairs]
          label_dt = 'Data value'   # TODO: I18n
          label_dd = 'Displayed as' # TODO: I18n
          html_tag(:dl) do
            opt = { class: 'label' } # First pair only
            { label_dt => label_dd }.merge!(cfg[:pairs]).map do |value, label|
              value = html_tag(:dt, value, opt)
              label = html_tag(:dd, label, opt)
              opt   = {}
              value << label
            end
          end
        else
          "Description of #{type.inspect} to come..." # TODO: ...
        end
      html_details(first, *lines, &block)
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
    # == Implementation Notes
    #
    def grid_control(type, expanded: false, css: '.grid-control', **opt)
      type_cfg  = GRID_HEADER[type] || {}
      state_cfg = expanded ? type_cfg[:closer] : type_cfg[:opener]
      label     = opt.delete(:label) || state_cfg[:label] || type_cfg[:label]
      opt[:title] ||= state_cfg[:tooltip] || type_cfg[:tooltip]
      prepend_css!(opt, 'expanded') if expanded
      prepend_css!(opt, css)
      html_button(label, opt)
    end

    # =========================================================================
    # :section: Item forms (remit page)
    # =========================================================================

    public

    # Submission status type keys and column labels.
    #
    # @type [Hash{Symbol=>String}]
    #
    SUBMIT_PHASE = BULK_GRID_CFG.dig(:status, :type)

    # Submission status grid column names.
    #
    # @type [Array<Symbol>]
    #
    SUBMIT_STATUS_COLUMNS = [:controls, :item_name, *SUBMIT_PHASE.keys].freeze

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
    S_FILE_NEEDED  = :file_needed
    S_FILE_MISSING = :file_missing
    S_DATA_MISSING = :data_missing

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
    # :section: Item forms (remit page)
    # =========================================================================

    public

    # submission_status_header
    #
    # @param [Integer] row
    # @param [String]  css
    # @param [Hash]    opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see #submit_status_element
    #
    def submission_status_header(row: 0, css: '.head', **opt)
      ctrl = nil
      name = 'Item Name' # TODO: I18n
      stat = SUBMIT_PHASE
      prepend_css!(opt, css)
      submit_status_element(ctrl, name, stat, row: row, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # submit_status_element
    #
    # @param [String, nil]          ctrl
    # @param [String, ManifestItem] item
    # @param [Hash{Symbol=>*}]      statuses
    # @param [Integer]              row
    # @param [Integer]              col
    # @param [String]               css
    # @param [Hash]                 opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def submit_status_element(
      ctrl,
      item,
      statuses,
      row:      1,
      col:      0,
      css:      '.submission-status',
      **opt
    )
      opt.delete(:index) # Just in cause this slipped in.
      heading = (row == 1)
      col_opt = { col: col, role: (heading ? 'columnheader' : 'cell') }

      # Item selection column.
      col_opt[:col] += 1
      ctrl = submit_status_ctls(ctrl, **col_opt) unless ctrl&.html_safe?

      # Item name column.
      col_opt[:col] += 1
      item = submit_status_item(item, **col_opt) unless item&.html_safe?

      # Status value columns.
      values =
        statuses.map do |type, stat|
          col_opt[:col] += 1
          stat = S_OK        if stat.is_a?(TrueClass)
          stat = S_BLANK     if stat.is_a?(FalseClass) || stat.nil?
          stat = stat.to_sym if stat.is_a?(String)
          # noinspection RubyMismatchedArgumentType
          submit_status_value(type, stat, **col_opt)
        end

      opt[:role] ||= 'row'
      opt[:'aria-rowindex'] = row
      opt[:separator] = '' unless opt.key?(:separator)
      prepend_css!(opt, css)
      html_div(ctrl, item, *values, opt)
    end

    # submit_status_ctls
    #
    # @param [String, nil]  ctrl
    # @param [Integer, nil] col
    # @param [String]       css
    # @param [Hash]         opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def submit_status_ctls(ctrl = nil, col: nil, css: '.controls', **opt)
      ctrl &&= html_div(ctrl, class: 'text') unless ctrl&.html_safe?
      ctrl ||=
        html_div(class: (cls = 'selection')) do
          name = 'Selection' # TODO: I18n
          id   = css_randomize(cls)
          h.check_box_tag(id) << h.label_tag(id, name)
        end
      opt[:role] ||= 'cell'
      opt[:'aria-colindex'] = col if col
      prepend_css!(opt, css)
      html_div(ctrl, opt)
    end

    # submit_status_item
    #
    # @param [String, ManifestItem] item
    # @param [Integer, nil]         col
    # @param [String]               css
    # @param [Hash]                 opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def submit_status_item(item, col: nil, css: '.item-name', **opt)
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
        r_opt = { separator: sep, no_format: true, no_help: true }
        lines = part.map { |k, v| render_pair(k.capitalize, v, **r_opt) } # TODO: I18n
        item  = html_details(first, *lines, class: 'text')
      else
        item  = html_div(item, class: 'text') unless item&.html_safe?
      end
      opt[:role] ||= 'cell'
      opt[:'aria-colindex'] = col if col
      prepend_css!(opt, css)
      html_div(item, opt)
    end

    # submit_status_value
    #
    # @param [Symbol]       type
    # @param [Symbol]       status
    # @param [Integer, nil] col
    # @param [String]       css
    # @param [Hash]         opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def submit_status_value(type, status, col:, css: '.status', **opt)
      entry  = SUBMIT_STATUS[status] || {}
      text   = submit_status_text(type, status, entry)
      button = (submit_status_link(type, status) if respond_to?(:object))
      opt[:role] ||= 'cell'
      opt[:'aria-colindex'] = col if col
      prepend_css!(opt, css, "#{type}-status", entry[:css])
      html_div(text, button, opt)
    end

    # The text on the status element.
    #
    # @param [Symbol] _type
    # @param [Symbol] status
    # @param [Hash]   entry
    # @param [String] css
    # @param [Hash]   opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def submit_status_text(_type, status, entry = {}, css: '.text', **opt)
      prepend_css!(opt, css)
      label   = entry[:text] || status.to_s
      details = STATUS_SHOW_DETAILS.include?(status)

      # Simple label.
      p_opt   = !details ? opt : append_css(opt, 'hidden')
      plain   = html_div(label, p_opt)

      # Expandable label.
      d_opt   = details ? opt : append_css(opt, 'hidden')
      details = html_tag(:summary, label) << html_div(class: 'name')
      details = html_tag(:details, details, d_opt)

      plain << details
    end

    # Control for fixing a condition resulting in a given status.
    #
    # @param [Symbol] _type
    # @param [Symbol] status
    # @param [String] css
    # @param [Hash]   opt
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    # @see file:javascripts/controllers/manifest-edit.js *scrollToCenter()*
    #
    def submit_status_link(_type, status, css: '.fix', **opt)
      label = 'Edit' # TODO: I18n
      row   = "data-item-id=#{object.id}"
      path  = h.edit_manifest_path(id: object.manifest_id, anchor: row)
      opt[:title] ||= 'Modify this manifest item' # TODO: I18n
      prepend_css!(opt, css)
      append_css!(opt, 'hidden') unless STATUS_SHOW_EDIT.include?(status)
      make_link(label, path, **opt, 'data-turbolinks': false)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # row_indicators
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
      html_div(opt) do
        ManifestItem::STATUS.map do |field, config|
          s_id   = "#{field}-indicator-#{id_base}"
          l_id   = "label-#{s_id}"

          value  = item[field]&.to_sym || :missing
          if (field == :ready_status) && (value == :ready) && item.unsaved?
            value = :unsaved
          end
          s_opt  = { 'data-field': field, id: s_id, 'aria-labelledby': l_id }
          status = row_indicator(value, **s_opt)

          text   = config[value] || value
          l_opt  = { 'data-field': field, id: l_id }
          label  = row_indicator_label(text, **l_opt)

          status << label
        end
      end
    end

    # row_details
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

          v_opt = { 'data-field': field, id: v_id, 'aria-labelledby': l_id }
          value = item[field] || EMPTY_VALUE
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
    # @option opt [String]        :'aria-labelledby'  Required
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def row_indicator(value, css: ".indicator.#{VALUE_CLASS}", **opt)
      field = opt[:'data-field']
      append_css!(opt, field, css, "value-#{value}")
      html_div(opt)
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
      html_div(label, opt)
    end

    # row_detail_value
    #
    # @param [String,Symbol] value
    # @param [String]        css
    # @param [Hash]          opt
    #
    # @option opt [String]        :id                 Required
    # @option opt [String,Symbol] :'data-field'       Required
    # @option opt [String]        :'aria-labelledby'  Required
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def row_detail_value(value, css: VALUE_CLASS, **opt)
      append_css!(opt, css)
      html_div(value, opt)
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
      html_div(label, opt)
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
      # noinspection RubyMismatchedArgumentType
      super((item || object), **opt)
    end

    # row_details
    #
    # @param [ManifestItem, nil] item   Default: `#object`.
    # @param [Hash]              opt    Passed to super
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def row_details(item = nil, **opt)
      # noinspection RubyMismatchedArgumentType
      super((item || object), **opt)
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
  # :section: BaseDecorator::List overrides
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
  def render_value(value, field:, **opt)
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
  def grid_row_control_contents(*added, row: nil, unique: nil, **opt)
    index = opt.delete(:index)
    r_opt = { row: row, unique: (unique || index || hex_rand) }

    added = [row_details(**r_opt), row_indicators(**r_opt), *added]
    added = [*added, *yield] if block_given?

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
    opt[:group] ||= object.try(:state_group)
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
  # @param [Hash]                prop
  # @param [Integer, nil]        col
  # @param [Hash]                opt
  #
  # @return [ActiveSupport::SafeBuffer]
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
  # @param [Symbol]    field          For 'data-field' attribute.
  # @param [*]         value
  # @param [Hash, nil] prop           Default: from field/model.
  # @param [Hash]      opt
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
    display  = html_div(opt)
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
    config     = FILE_TYPE_CFG[src] || {}
    type       = config[:type]  || src
    type_class = config[:class] || "from-#{type}"
    prepend_css!(opt, type_class)

    id     = opt.delete(:id) || unique_id
    button = file_input_ctrl(src: src, id: id, **opt)
    panel  = file_input_panel(src: src, id: id, **opt)

    prepend_css!(opt, css).merge!('data-src': src, 'data-type': type)
    html_div(opt) do
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
    config = FILE_TYPE_CFG[src] || {}
    label  = config[:label]
    prepend_css!(opt, css)
    html_button(label, opt)
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
    config      = FILE_TYPE_CFG[src] || {}
    type        = config[:type]  || src
    type_class  = config[:class] || "from-#{type}"
    panel_cfg   = config[:panel] || {}

    desc_opt    = append_css(opt, 'description').merge!(for: id)
    description = config[:description]
    description = h.label_tag(nil, description, desc_opt)

    label       = panel_cfg[:label]
    name        = html_id(type || label)
    input_id    = "#{name}-#{id}"
    input_opt   = append_css(opt, 'input')
    input_label = h.label_tag(name, label, input_opt.merge(for: input_id))
    input_field = h.text_field_tag(name, nil, input_opt.merge(id: input_id))

    input_submit, input_cancel =
      %i[submit cancel].map do |key|
        b_lbl = panel_cfg[key]
        b_opt = append_css(input_opt, "input-#{key}", "#{type_class}-#{key}")
        html_button(b_lbl, b_opt)
      end

    prepend_css!(opt, css).merge!('data-id': id)
    html_div(opt) do
      description << input_label << input_field << input_submit << input_cancel
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
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

  # details_container
  #
  # @param [Array]         added      Optional elements after the details.
  # @param [Array<Symbol>] skip       Display aspects to avoid.
  # @param [Hash]          opt        Passed to super
  # @param [Proc]          block      Passed to super
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details_container(*added, skip: [], **opt, &block)
    skip = Array.wrap(skip)
    added.prepend(cover(placeholder: false)) unless skip.include?(:cover)
    super(*added, **opt, &block)
  end

  # ===========================================================================
  # :section: Item forms (remit page)
  # ===========================================================================

  public

  # submission_status
  #
  # @param [Integer, nil] row
  # @param [Integer]      col
  # @param [Hash]         opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #submit_status_element
  #
  def submission_status(row: nil, col: 1, **opt)
    ctrl = submit_status_ctls(col: col)
    stat = SUBMIT_PHASE.transform_values { nil }
    stat[:index]  = object.in_index?
    stat[:upload] = object.file_uploaded?
    stat[:file]   = stat[:upload]   || object.file_literal?
    stat[:file] ||= object.file_ok?  ? S_FILE_NEEDED : S_FILE_MISSING
    stat[:db]     = object.unsaved? && S_UNSAVED
    stat[:db]   ||= object.data_ok? || S_DATA_MISSING
    if Log.debug? && (skipped = stat.select { |_, v| v.nil? }).present?
      Log.debug { "#{__method__}: not handling status types: #{skipped.keys}" }
    end
    opt[:'data-item-id']   ||= object.id
    opt[:'data-manifest']  ||= object.manifest_id
    opt[:'data-file-name'] ||= object.pending_file_name
    opt[:'data-file-url']  ||= object.pending_file_url
    submit_status_element(ctrl, object, stat, row: row, **opt)
  end

  # ===========================================================================
  # :section: BaseDecorator overrides
  # ===========================================================================

  public

  # Client-side scripting which are supplied via 'assets:precompile'.
  #
  # @param [Hash{Symbol=>Any}]
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
