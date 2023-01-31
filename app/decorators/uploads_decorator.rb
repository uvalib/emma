# app/decorators/uploads_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/upload" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Upload>]
#
class UploadsDecorator < BaseCollectionDecorator

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include UploadDecorator::SharedInstanceMethods
    extend  UploadDecorator::SharedClassMethods
    # :nocov:
  end

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of UploadDecorator

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # group_counts
  #
  # @return [Hash{Symbol=>Integer}]
  #
  def group_counts
    @group_counts ||= context[:group_counts] || {}
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Select records based on workflow state group.
  #
  # @param [Hash]   counts            A table of group names associated with
  #                                     their overall totals (default:
  #                                     `#group_counts`).
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to inner #html_div except for:
  #
  # @option opt [String]        :curr_path    Default: `request.fullpath`
  # @option opt [String,Symbol] :curr_group   Default from `request_parameters`
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #STATE_GROUP
  # @see LinkHelper#make_link
  # @see file:app/assets/javascripts/feature/records.js *filterPageDisplay()*
  #
  def state_group_select(counts: nil, css: GROUP_PANEL_CLASS, **opt)
    curr_path  = opt.delete(:curr_path)  || request_value(:fullpath)
    curr_group = opt.delete(:curr_group) || param_values[:group] || :all
    curr_group = curr_group.to_sym if curr_group.is_a?(String)
    counts   ||= group_counts

    # A label preceding the group of buttons (screen-reader only).
    p_id   = "label-#{GROUP_CLASS}"
    prefix = 'Select records based on their submission state:' # TODO: I18n
    prefix = html_div(prefix, id: p_id, class: 'sr-only')

    # Create buttons for each state group that has entries.
    buttons =
      STATE_GROUP.map do |group, properties|
        all     = (group == :all)
        count   = counts[group] || 0
        enabled = all || count.positive?
        next unless enabled || session_debug?

        label = properties[:label] || group
        label = html_span(label, class: 'label')
        label << html_span("(#{count})", class: 'count')

        base  = index_path
        url   = all ? base : index_path(group: group)

        link_opt = append_css('control-button', GROUP_CONTROL_CLASS)
        link_opt[:'aria-label'] = properties[:tooltip]
        link_opt[:'data-group'] = group
        append_css!(link_opt, 'current')  if group == curr_group
        append_css!(link_opt, 'disabled') if url   == curr_path
        append_css!(link_opt, 'hidden')   unless enabled

        make_link(label, url, **link_opt)
      end

    # Wrap the controls in a group.
    prepend_css!(opt, GROUP_CLASS)
    opt[:role]              = 'navigation'
    opt[:'aria-labelledby'] = p_id
    group = html_div(*buttons, opt)

    # An element following the group to hold a dynamic description of the group
    # button currently hovered/focused.  (@see javascripts/feature/records.js)
    note = html_div(HTML_SPACE, class: 'note', 'aria-hidden': true)
    note = html_div(note, class: 'note-tray', 'aria-hidden': true)

    # Include the group and note area in a panel.
    html_div(class: css_classes(css)) do
      prefix << group << note
    end
  end

  # ===========================================================================
  # :section: BaseCollectionDecorator::List overrides
  # ===========================================================================

  public

  # Control for filtering which records are displayed.
  #
  # @param [Hash]   counts            A table of group names associated with
  #                                     their overall totals (default:
  #                                     `#group_counts`).
  # @param [Hash]   outer             HTML options for outer fieldset.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to inner #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If #LIST_FILTERING is *false*.
  #
  # @see #STATE_GROUP
  # @see file:app/assets/javascripts/feature/records.js *filterPageDisplay()*
  #
  def list_filter(counts: nil, outer: nil, css: LIST_FILTER_CLASS, **opt)
    return unless LIST_FILTERING
    name     = "#{model_type}-#{__method__}"
    list     = object
    table    = list.group_by(&:state_group)
    counts ||= group_counts

    # Create radio button controls for each state group that has entries.
    ctrl_opt = append_css(FILTER_CONTROL_CLASS)
    controls =
      STATE_GROUP.map do |group, properties|
        items     = table[group]  || []
        all       = (group == :all)
        count     = counts[group] || (all ? list.size : items.size)
        enabled   = all || count.positive?
        enabled ||= active_state_group?(nil, properties, items)
        next unless enabled || session_debug?

        input_id  = "#{name}-#{group}"
        label_id  = "label-#{input_id}"
        tooltip   = properties[:tooltip]
        selected  = true?(properties[:default])

        i_opt     = { role: 'radio' }
        input     = h.radio_button_tag(name, group, selected, i_opt)

        l_opt     = { id: label_id }
        label     = ERB::Util.h(properties[:label] || group.to_s)
        label     = "#{label}&thinsp;(#{count})".html_safe if count
        label     = h.label_tag(input_id, label, l_opt)

        html_opt  = ctrl_opt.merge(title: tooltip, 'data-group': group)
        append_css!(html_opt, 'hidden') unless enabled
        html_div(html_opt) { input << label }
      end

    # Text before the radio buttons:
    prefix = 'On this page:' # TODO: I18n
    prefix = html_span(prefix, class: 'prefix', 'aria-hidden': true)
    controls.unshift(prefix)

    # Wrap the controls in a group.
    prepend_css!(opt, FILTER_GROUP_CLASS)
    opt[:role] = 'radiogroup'
    group = html_div(controls, opt)

    # A label for the group (screen-reader only).
    legend = "Choose the #{model_type} submission state to display:" # TODO: I18n
    legend = html_tag(:legend, legend, class: 'sr-only')

    # Include the group in a panel with accompanying label.
    outer_opt = prepend_css(outer, css)
    append_css!(outer_opt, 'hidden') unless controls.many?
    h.field_set_tag(nil, outer_opt) do
      legend << group
    end
  end

  # ===========================================================================
  # :section: BaseCollectionDecorator::List overrides
  # ===========================================================================

  public

  # Control the selection of filters displayed by #list_filter.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_div for outer *div*.
  #
  # @option opt [Array] :records      List of upload records for display.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/records.js *filterOptionToggle()*
  #
  def list_filter_options(css: FILTER_OPTIONS_CLASS, **opt)
    name   = "#{model_type}-#{__method__}"
    list   = object
    counts = group_counts

    # A label preceding the group (screen-reader only).
    legend = 'Select/de-select state groups to show' # TODO: I18n
    legend = html_tag(:legend, legend, class: 'sr-only')

    # Checkboxes.
    cb_opt = { class: FILTER_CONTROL_CLASS }
    groups = { ALL_FILTERS: { label: 'Show all filters', checked: false } }
    groups.merge!(STATE_GROUP)
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

    prepend_css!(opt, css)
    html_tag(:fieldset, legend, *checkboxes, opt)
  end

  # ===========================================================================
  # :section: BaseCollectionDecorator::Form overrides
  # ===========================================================================

  public

  # Labels for inputs associated with transmitted parameters. # TODO: I18n
  #
  # @type [Hash{Symbol=>String}]
  #
  DELETE_LABEL = {
    emergency:  'Attempt to remove index entries for bogus non-EMMA items?',
    force:      'Try to remove index entries of items not in the database?',
    truncate:   'Reset "uploads" id field to 1?' \
                ' (Applies only when all records are being removed.)',
  }.freeze

  # delete_submit_option_keys
  #
  # @return [Array<Symbol>]
  #
  def delete_submit_option_keys
    DELETE_LABEL.keys
  end

  # delete_submit_path
  #
  # @param [Array<Upload,String>, Upload, String, nil] ids
  # @param [Hash]                                      opt
  #
  # @return [String, nil]
  #
  def delete_submit_path(ids = nil, **opt)
    opt.reverse_merge!(options.all)
    super(ids, **opt)
  end

  # ===========================================================================
  # :section: BaseCollectionDecorator::Form overrides
  # ===========================================================================

  protected

  # item_ids
  #
  # @param [Array<Upload,String>, Upload, String, nil] items  Def: `#object`
  # @param [Hash]                                      opt
  #
  # @return [Array<String>]
  #
  def item_ids(items = nil, **opt)
    items = records_or_sid_ranges(context[:list]) if opt[:force]
    items ||= object
    Upload.compact_ids(*items)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # records_or_sid_ranges
  #
  # @param [Array<Model,String>, nil] list
  #
  # @return [Array<Model,String>, nil]
  #
  def records_or_sid_ranges(list)
    return if list.blank?
    rids    = list.select { |e| e.is_a?(String) && e.match?(/^[^\d]/) }
    recs, _ = find_in_index(*rids)
    lookup  = record_map(recs)
    items   = list.map { |item| lookup[item] || item }
    items.select { |item| item.is_a?(Model) || item.include?('-') }
  end

  # find_in_index
  #
  # @param [Array<String,Upload>] items
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

  # record_map
  #
  # @param [Array<Model>] records
  #
  # @return [Hash{String=>String}]
  #
  def record_map(records)
    records.map { |rec| [rec.emma_repositoryRecordId, rec.emma_recordId] }.to_h
  end

  # ===========================================================================
  # :section: Bulk new/edit/delete pages
  # ===========================================================================

  public

  # Initially hidden container used by the client to display intermediate
  # results during a bulk operation.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_op_results(css: '.bulk-op-results', **opt)
    l_sel = "#{css}-label"
    l_id  = unique_id(l_sel)
    label = 'Previous upload results:' # TODO: I18n
    label = html_div(label, id: l_id, class: css_classes(l_sel, 'hidden'))

    prepend_css!(opt, css)
    append_css!(opt, 'hidden')
    opt[:'aria-labelledby'] = l_id
    panel = html_div(opt)

    label << panel
  end

  # ===========================================================================
  # :section: Bulk new/edit/delete pages
  # ===========================================================================

  protected

  # An option checkbox for a bulk operation form.
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           param
  # @param [Any, nil]                         value
  # @param [Hash{Symbol=>String}]             labels
  # @param [Boolean]                          debug_only
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see FormHelper#hidden_input
  #
  def bulk_option(f, param, value = nil, labels:, debug_only: false, **)
    if debug_only && !session_debug?
      hidden_input(param, value)
    else
      label = f.label(param, labels[param])
      check = f.check_box(param, checked: value)
      html_div(class: 'line') { check << label }
    end
  end

  # An input element for a bulk operation form.
  #
  # @param [ActionView::Helpers::FormBuilder] f
  # @param [Symbol]                           param
  # @param [Any, nil]                         value
  # @param [Hash{Symbol=>String}]             labels
  # @param [Symbol]                           meth
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_input(f, param, value = nil, labels:, meth: :text_field, **opt)
    label = f.label(param, labels[param])
    input = f.send(meth, param, value: value, **opt)
    html_div(class: 'line') { label << input }
  end

  # ===========================================================================
  # :section: Bulk new/edit pages
  # ===========================================================================

  public

  # Labels for inputs associated with transmitted parameters. # TODO: I18n
  #
  # @type [Hash{Symbol=>String}]
  #
  BULK_LABEL = {
    prefix: 'Title prefix:',
    batch:  'Batch size:'
  }.freeze

  # @private
  BULK_OPTIONS = BULK_LABEL.keys.freeze

  # Generate a form with controls for uploading a file, entering metadata, and
  # submitting.
  #
  # @param [String]         label     Label for the submit button.
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [Hash]           outer     HTML options for outer div container.
  # @param [String]         css       Characteristic CSS class/selector.
  # @param [Hash]           opt       Passed to #form_with except for:
  #
  # @option opt [String]  :prefix     String to prepend to each title.
  # @option opt [Integer] :batch      Size of upload batches.
  # @option opt [String]  :cancel     URL for cancel button action.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see FormHelper#hidden_input
  #
  def bulk_op_form(
    label:  nil,
    action: nil,
    outer:  nil,
    css:    '.bulk-op-form',
    **opt
  )
    outer_css = '.form-container.bulk'
    action    = action&.to_sym || context[:action] || DEFAULT_FORM_ACTION

    case action
      when :delete, :bulk_delete
        return bulk_delete_form(label: label, **opt)
      when :edit, :bulk_edit
        opt[:method] ||= :put
        opt[:url]      = bulk_update_path
      when :new, :bulk_new
        opt[:method] ||= :post
        opt[:url]      = bulk_create_path
      else
        Log.warn("#{__method__}: #{action}: unexpected action")
    end
    opt[:multipart]    = true
    opt[:autocomplete] = 'off'

    prepend_css!(opt, css, action, model_type)
    scroll_to_top_target!(opt)

    outer_opt = prepend_css(outer, outer_css, action, model_type)
    html_div(outer_opt) do

      cancel   = opt.delete(:cancel)
      ctrl_opt = { class: 'bulk' }
      btn_opt  = ctrl_opt.merge(action: action)
      bulk_opt = extract_hash!(opt, *BULK_OPTIONS)
      bulk_opt[:prefix] ||= options.title_prefix
      bulk_opt[:batch]  ||= options.batch_size

      form_with(**opt) do |f|
        lines = []

        # === Batch title prefix input
        param = :prefix
        value = bulk_opt[param].presence
        if session_debug?
          lines << bulk_op_input(f, param, value)
        elsif value
          lines << hidden_input(param, value)
        end

        # === Batch size control
        param = :batch
        value = bulk_opt[param].presence
        lines << bulk_op_input(f, param, value, min: 0, meth: :number_field)

        # === Form control panel
        lines <<
          html_div(class: 'form-controls') do
            submit   = submit_button(label: label,  **btn_opt)
            cancel   = cancel_button(url:   cancel, **btn_opt)
            input    = bulk_op_file_select(f, :source, **ctrl_opt)
            uploaded = uploaded_filename_display(**ctrl_opt)
            tray_opt = prepend_css(ctrl_opt, 'button-tray')
            html_div(tray_opt) { submit << cancel << input << uploaded }
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
  def bulk_op_option(f, param, value = nil, **opt)
    opt[:labels] ||= BULK_LABEL
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
  def bulk_op_input(f, param, value = nil, **opt)
    opt[:labels] ||= BULK_LABEL
    bulk_input(f, param, value, **opt)
  end

  # bulk_op_file_select
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
  def bulk_op_file_select(f, meth, **opt)
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

  BULK_DELETE_LABEL = # TODO: I18n
    DELETE_LABEL.merge(selected: 'Items to delete:').freeze

  # Generate a form with controls for getting a list of identifiers to pass on
  # to the "/upload/delete" page.
  #
  # @param [String] label             Label for the submit button.
  # @param [Hash]   outer             HTML options for outer div container.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #form_with except for:
  #
  # @option opt [Boolean] :force      Force index delete option
  # @option opt [Boolean] :truncate   Reset database ID option
  # @option opt [Boolean] :emergency  Emergency force delete option
  # @option opt [String]  :cancel     URL for cancel button action.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bulk_delete_form(
    label: nil,
    outer: nil,
    css: '.bulk-op-form.delete',
    **opt
  )
    outer_css = '.form-container.bulk.delete'
    action    = :bulk_delete
    ids       = item_ids.presence

    opt[:url]          = delete_select_path
    opt[:method]     ||= :get
    opt[:autocomplete] = 'off'
    opt[:local]        = true # Turns off "data-remote='true'".

    prepend_css!(opt, css, model_type)

    outer_opt = prepend_css(outer, outer_css, model_type)
    html_div(outer_opt) do

      cancel  = opt.delete(:cancel)
      sub_opt = options.all
      opt.except!(*sub_opt.keys)

      form_with(**opt) do |f|
        lines = []

        # === Options
        dbg = { debug_only: true }
        { force: {}, truncate: dbg, emergency: dbg }.each_pair do |prm, vals|
          next if (value = sub_opt[prm]).nil?
          lines << bulk_delete_option(f, prm, value, **vals)
        end

        # === Item selection input
        lines << bulk_delete_input(f, :selected, ids)

        # === Form control panel
        lines <<
          html_div(class: 'form-controls') do
            html_div(class: 'button-tray') do
              btn_opt   = { action: action }
              buttons   = []
              buttons  << submit_button(label: label,  **btn_opt)
              buttons  << cancel_button(url:   cancel, **btn_opt)
              safe_join(buttons)
            end
          end

        safe_join(lines, "\n")
      end
    end
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
  def bulk_delete_option(f, param, value = nil, **opt)
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
  def bulk_delete_input(f, param, value = nil, **opt)
    opt[:labels] ||= BULK_DELETE_LABEL
    bulk_input(f, param, value, **opt)
  end

end

__loading_end(__FILE__)
