# app/decorators/manifest_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/manifest" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Manifest]
#
class ManifestDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for Manifest

  # ===========================================================================
  # :section: Definitions shared with ManifestsDecorator
  # ===========================================================================

  public

  module SharedPathMethods

    include BaseDecorator::SharedPathMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def upload_path(*, **opt)
      h.manifest_item_upload_path(**opt)
    end

    def remit_select_path(*, **opt)
      path_for(**opt, action: :remit_select)
    end

    def remit_path(item = nil, **opt)
      path_for(item, **opt, action: :remit)
    end

=begin # TODO: submission start/stop ?
    def start_path(item = nil, **opt)
      path_for(item, **opt, action: :start)
    end

    def stop_path(item = nil, **opt)
      path_for(item, **opt, action: :stop)
    end

    def pause_path(item = nil, **opt)
      path_for(item, **opt, action: :pause)
    end

    def resume_path(item = nil, **opt)
      path_for(item, **opt, action: :resume)
    end
=end

  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module SharedGenericMethods

    include BaseDecorator::SharedGenericMethods
    include BaseDecorator::Grid

    extend Emma::Common::FormatMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @private
    # @type [String]
    ITEM_NAME = ManifestController.unit[:item]

    # Bulk submission configuration values.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    BULK_SUBMIT_CFG = config_section(:bulk, :submit).deep_freeze

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
      }.deep_freeze

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
      super(%i[new edit delete remit])
    end

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    public

    # Generate a menu of manifest instances.
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
      user = nil if user == :all
      config_term(:manifest, (user ? :select_own : :select_any))
    end

    # =========================================================================
    # :section: BaseDecorator::Pagination overrides
    # =========================================================================

    public

    # The element displayed when the user has no Manifests to list.
    #
    # @param [String] css             Characteristic CSS class/selector.
    # @param [Hash]   opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def no_items(css: '.no-items', **opt)
      ctrl = new_button(config_term(:manifest, :create_button))
      desc = config_term(:manifest, :no_items, control: ctrl)
      prepend_css!(opt, css)
      h.page_description_section(desc, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # The button displayed when the user has no Manifests to list.
    #
    # @param [String, nil] label
    # @param [String]      css        Characteristic CSS class/selector.
    # @param [Hash]        opt        Passed to #link_to_action.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def new_button(label = nil, css: '.new-button', **opt)
      label ||= config_term(:manifest, :new_label)
      prepend_css!(opt, css)
      link_to_action(label, action: :new, link_opt: opt)
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

    # Create a value for #context based on the parameters supplied through the
    # initializer.
    #
    # @param [Hash] opt
    #
    # @return [Hash]                  Suitable for assignment to #context.
    #
    def initialize_context(**opt)
      super.tap do |ctx|
        ctx[:cancel] ||= index_path
      end
    end

    # options
    #
    # @return [Manifest::Options]
    #
    def options
      context[:options] || Manifest::Options.new
    end

    # help_topic
    #
    # @param [Symbol, nil] sub_topic  Default: `context[:action]`.
    # @param [Symbol, nil] topic      Default: `model_type`.
    #
    # @return [Array<Symbol>]
    #
    def help_topic(sub_topic = nil, topic = nil)
      case context[:action]
        when :edit  then sub_topic = :grid       if params[:selected]
        when :remit then sub_topic = :submission if params[:selected]
      end
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

#--
# noinspection RubyTooManyMethodsInspection
#++
class ManifestDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

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
    if present? && object.field_names.include?(field)
      object[field] || EMPTY_VALUE
    end || super
  end

  # ===========================================================================
  # :section: BaseDecorator::Pagination overrides
  # ===========================================================================

  public

  # Page count label for manifest items.
  #
  # @param [Hash] opt               Passed to #config_lookup
  #
  # @option opt [Integer] :count
  #
  # @return [String]                The specified value.
  # @return [nil]                   No non-empty value was found.
  #
  def get_page_count_label(**opt)
    config_lookup('pagination.count', **opt, ctrlr: row_model_type)
  end

  # The collection of rows associated with the manifest.
  #
  # @return [ManifestItem::Paginator]
  #
  def paginator
    @paginator ||=
      context[:paginator] || ManifestItem::Paginator.new(h.controller)
  end

  # ===========================================================================
  # :section: BaseDecorator::Row overrides
  # ===========================================================================

  public

  # The #model_type of individual associated items for iteration.
  #
  # @return [Symbol]
  #
  def row_model_type
    :manifest_item
  end

  # The class of individual associated items for iteration.
  #
  # @return [Class]
  #
  def row_model_class
    ManifestItem
  end

  # The collection of rows associated with the manifest.
  #
  # @param [Hash] _opt                TODO: How to make use of this here?
  #
  # @return [ActiveRecord::Associations::HasManyAssociation]
  #
  def row_items(**_opt)
    object.manifest_items.scope.active
  end

  # The names of each ManifestItem column which is not displayed.
  #
  # @return [Array<Symbol>]
  #
  def row_skipped_columns
    ManifestItemDecorator.send(__method__)
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

  # ===========================================================================
  # :section: BaseDecorator::Grid overrides
  # ===========================================================================

  public

  # Render associated items.
  #
  # @param [Hash] opt                 Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grid(**opt)
    opt[:'data-manifest']     = object.id
    opt[:'aria-labelledby'] ||= page_heading_id
    super
  end

  # The names of each grid data column which is not displayed.
  #
  # @return [Array<Symbol>]
  #
  def grid_row_skipped_columns
    ManifestItemDecorator.send(__method__)
  end

  # The names of each grid data column which is rendered but not visible.
  #
  # @return [Array<Symbol>]
  #
  def grid_row_undisplayed_columns
    ManifestItemDecorator.send(__method__)
  end

  # Show a button for expanding/contracting the controls column in the top
  # left grid cell.
  #
  # @param [Hash] opt
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def grid_head_control_headers(**opt)
    ManifestItemDecorator.send(__method__, **opt)
  end

  # Render a grid header cell.
  #
  # @param [Symbol, nil] col          Data column.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_head_cell(col, **opt)
    ManifestItemDecorator.send(__method__, col, **opt)
  end

  # ===========================================================================
  # :section: BaseDecorator::Form overrides
  # ===========================================================================

  public

  # Single-select menu - dropdown.
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

  # Basic form controls, including #import_button if appropriate.
  #
  # @param [Hash] opt
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  # @yield [parts] Extend or replace results.
  # @yieldparam [Array<ActiveSupport::SafeBuffer>] parts
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>, nil]
  #
  def form_buttons(**opt)
    trace_attrs!(opt)
    opt[:action]          ||= context[:action] || DEFAULT_FORM_ACTION
    opt[:'data-manifest'] ||= object.id
    buttons = super
    buttons << submission_button(**opt)
    buttons << export_button(**opt)
    buttons << import_button(**opt)
    buttons << comm_status(**opt)
    block_given? && yield(buttons) || buttons
  end

  # Form submit button.
  #
  # @param [Hash] opt                 Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submit_button(**opt)
    opt[:state] ||= (:enabled if object.manifest_items.pending.present?)
    super
  end

  # Submit cancel button.
  #
  # @param [Hash] opt                 Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def cancel_button(**opt)
    opt[:'data-path'] ||= opt.delete(:url) || context[:cancel] || back_path
    super
  end

  # ===========================================================================
  # :section: Manifest forms
  # ===========================================================================

  public

  # A consistent HTML element ID for the page heading.
  #
  # @return [String]
  #
  def page_heading_id
    ['page-heading', model_type, object.id].compact.join('-')
  end

  # For use on view templates in place of LayoutHelper#page_heading to support
  # editing the Manifest title.
  #
  # @param [ActiveSupport::SafeBuffer, Array<Symbol>, Symbol, nil] help
  # @param [Hash]                                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def manifest_page_heading(help: nil, **opt)
    text  = config_term_section(:manifest, :heading)
    name  = object.name

    t_lbl = html_span(class: 'text label') { text[:leader]}
    t_nam = html_span(class: 'text name')  { name }
    title = t_lbl << t_nam

    e_lbl = text[:edit_label]
    e_tip = text[:edit_tooltip]
    edit  = html_button(e_lbl, title: e_tip, class: 'title-edit')

    input = model_line_editor(pairs: { name: name })

    help  = h.page_heading_help(help)

    opt[:id] ||= page_heading_id
    h.page_heading(title, edit, input, help, **opt)
  end

  # Import manifest items from an external source.
  #
  # @param [Hash] opt                 Passed to #form_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/controllers/manifest-edit.js *importRows*
  # @see file:app/assets/stylesheets/feature/_model_form.scss ".import-button"
  #
  def import_button(**opt)
    opt[:accept] = 'text/csv,text/comma-separated-values'
    form_button(:import, **opt, type: :file)
  end

  # Export manifest items to an external file.
  #
  # @param [Hash] opt                 Passed to #form_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/controllers/manifest-edit.js *exportRows*
  # @see file:app/assets/stylesheets/feature/_model_form.scss ".export-button"
  #
  def export_button(**opt)
    append_css!(opt, 'hidden') # TODO: remove after implementing Manifest export
    form_button(:export, **opt)
  end

  # Submit this manifest.
  #
  # @param [Hash] opt                 Passed to #form_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submission_button(**opt)
    unless opt[:url]
      id = opt[:'data-manifest'] || object.id
      opt[:url] = id ? remit_path(id: id) : remit_select_path
    end
    form_button(:submission, **opt)
  end

  # Pre-defined status messages for #comm_status.
  #
  # @type [Hash{Symbol=>String}]
  #
  STATUS_MESSAGE = {
    offline: config_term(:status, :offline),
    dynamic: '',
  }.deep_freeze

  # An area for transient status messages updated by the client if there are
  # problems communicating with the server.
  #
  # @param [String]              css      Characteristic CSS class/selector.
  # @param [Symbol, String, nil] status   Initial status.
  # @param [Hash]                opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def comm_status(css: '.comm-status', status: nil, **opt)
    opt[:role] = 'status' unless opt.key?(:role)
    opt.except!(*FORM_BUTTON_OPT)
    prepend_css!(opt, css, status)
    html_div(**opt) do
      STATUS_MESSAGE.map { |type, text| html_span(text, class: type) }
    end
  end

  # ===========================================================================
  # :section: Manifest submission
  # ===========================================================================

  public

  # Submission button types.
  #
  # @type [Array<Symbol>]
  #
  SUBMISSION_BUTTONS = BULK_SUBMIT_CFG[:buttons].map(&:to_sym).freeze

  # ManifestItem entries to be submitted.
  #
  # By default, all items are selected -- given the client the responsibility
  # of prevent submission of non-submittable items.
  #
  # @param [Boolean] limit            If *true* select only eligible items.
  #
  # @return [ActiveRecord::Relation<ManifestItem>]
  #
  def submit_items(limit: false)
    limit ? object.manifest_items.could_submit : object.manifest_items.active
  end

  # Primary submission controls plus #submisson_counts.
  #
  # @param [Array<ActiveSupport::SafeBuffer>] added
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               To #form_button
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submission_button_tray(*added, css: '.submission-controls', **opt)
    prepend_css!(opt, css)
    opt[:'data-manifest'] ||= object.id
    buttons = SUBMISSION_BUTTONS.map { |type| submission_control(type) }
    form_button_tray(*buttons, *added, submission_counts, **opt)
  end

  # Submission process control button.
  #
  # @param [Symbol] type
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               To #form_button
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submission_control(type, css: '.submission-control', **opt)
    prepend_css!(opt, css)
    opt[:control] = ->(**o) { monitor_control(button: o) } if type == :monitor
    form_button(type, **opt)
  end

  # ===========================================================================
  # :section: Manifest submission
  # ===========================================================================

  public

  # Submission count types.
  #
  # @type [Hash{Symbol=>String}]
  #
  SUBMISSION_COUNTS =
    BULK_SUBMIT_CFG[:counts].map { |type, entry|
      lbl = entry.is_a?(Hash) && entry[:label] || entry || type.to_s
      lbl = lbl.downcase
      [type, lbl.freeze]
    }.compact.to_h.freeze

  # Submission counts display.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submission_counts(css: '.submission-counts', **opt)
    prepend_css!(opt, css)
    html_div(**opt) do
      SUBMISSION_COUNTS.map do |type, label|
        number = (type == :total) ? submit_items.size : 0
        submission_count(type, number, label: label)
      end
    end
  end

  # Submission count.
  #
  # @param [Symbol]       type
  # @param [Integer, nil] count
  # @param [String, nil]  label       Default: from #SUBMISSION_COUNTS.
  # @param [String]       css         Characteristic CSS class/selector.
  # @param [Hash]         opt         To #html_span
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submission_count(type, count = nil, label: nil, css: '.count', **opt)
    lbl = html_span(class: 'label') { label || SUBMISSION_COUNTS[type] }
    val = html_span(class: 'value') { positive(count) || 0 }
    prepend_css!(opt, type, css)
    html_span(**opt) do
      lbl << val
    end
  end

  # ===========================================================================
  # :section: Manifest submission
  # ===========================================================================

  public

  # Submission auxiliary buttons.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SUBMISSION_AUXILIARY = BULK_SUBMIT_CFG[:auxiliary]

  # auxiliary_button_tray
  #
  # @param [Array<ActiveSupport::SafeBuffer>] added
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               To #form_button_tray
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def auxiliary_button_tray(*added, css: '.auxiliary-buttons', **opt)
    prepend_css!(opt, css)
    opt[:'data-manifest'] ||= object.id
    buttons = [submission_remote, submission_local]
    form_button_tray(*buttons, *added, **opt)
  end

  # A button and text panel to display to resolve items whose :file_data
  # indicates a local file that needs to be acquired in order to proceed with
  # automated batch submission.
  #
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to #submission_files.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submission_local(css: '.local-file', **opt)
    opt[:config] ||= SUBMISSION_AUXILIARY[:local]
    submission_files(css: css, multiple: true, **opt)
  end

  # A button and text panel to display to resolve items whose :file_data
  # indicates a remote file that needs to be acquired in order to proceed with
  # automated batch submission.
  #
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to #submission_files.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submission_remote(css: '.remote-file', **opt)
    opt[:config] ||= SUBMISSION_AUXILIARY[:remote]
    submission_files(css: css, multiple: true, **opt)
  end

  # ===========================================================================
  # :section: Manifest submission
  # ===========================================================================

  protected

  # A button and text panel.
  #
  # @param [Boolean] hidden           If *false* show initially.
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    config           Configuration properties.
  # @param [Hash]    opt              Button options.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submission_files(hidden: true, css: nil, config: {}, **opt)
    b_opt  = { label: config[:label], title: config[:tooltip] }.merge!(opt)
    b_opt  = append_css!(b_opt, 'best-choice', css)
    b_opt  = append_css!(b_opt, 'hidden') if hidden
    button = form_button(:file, **b_opt.compact)

    n_opt  = append_css!({}, 'panel', css)
    n_opt  = append_css!(n_opt, 'hidden') if hidden
    notice = config[:description_html]&.html_safe || config[:description]
    notice = html_div(notice, **n_opt)

    button << notice
  end

  # ===========================================================================
  # :section: Manifest submission
  # ===========================================================================

  public

  # The row number of the grid header.
  #
  # @type [Integer]
  #
  HEADER_ROW = 1

  # @private
  # @type [Integer]
  STATUS_COLUMN_COUNT = ManifestItemDecorator::SUBMIT_COLUMNS.size

  # @private
  # @type [String]
  STATUS_LABELS = ManifestItemDecorator::SUBMIT_STATUS_LABELS.to_json.freeze

  # The live table of in-progress and completed submissions.
  #
  # @param [Integer, nil] row
  # @param [Integer, nil] index
  # @param [Symbol]       tag         Default: :table
  # @param [String]       css         Characteristic CSS class/selector.
  # @param [Hash]         opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submission_status_grid(
    row:    HEADER_ROW,
    index:  nil,
    tag:    nil,
    css:    '.submission-status-grid',
    **opt
  )
    index ||= paginator.first_index
    r_start = row || 0
    table   = for_html_table?(tag)
    tag     = table && :table || tag || :div

    opt[:thead] =
      ManifestItemDecorator.submission_status_header(tag: tag, row: row)
    row += 1 if opt[:thead]

    # noinspection RubyMismatchedArgumentType
    rows =
      submit_items.map.with_index(index) do |item, i|
        decorate(item).submission_status(tag: tag, index: i, row: (row + i))
      end
    row += rows.size
    opt[:tbody] = table ? html_tbody(*rows) : safe_join(rows, "\n")

    opt[:'data-labels']   ||= STATUS_LABELS
    opt[:'aria-colcount'] ||= STATUS_COLUMN_COUNT
    opt[:'aria-rowcount'] ||= row - r_start
    ManifestsDecorator.new.render_grid(index: index, tag: tag, css: css, **opt)
  end

  # ===========================================================================
  # :section: BaseDecorator overrides
  # ===========================================================================

  public

  # Client-side scripting which are supplied via 'assets:precompile'.
  #
  # @return [Hash]
  #
  # @see file:app/assets/javascripts/shared/assets.js.erb  *Emma.Manifest*
  #
  def self.js_properties
    path_properties = {
      upload: upload_path,
      remit:  remit_path(id: JS_ID),
=begin # TODO: submission start/stop ?
      start:  start_path(id: JS_ID),
      stop:   stop_path(id: JS_ID),
      pause:  pause_path(id: JS_ID),
      resume: resume_path(id: JS_ID),
=end
    }
    super.deep_merge!(Path: path_properties)
  end

end

__loading_end(__FILE__)
