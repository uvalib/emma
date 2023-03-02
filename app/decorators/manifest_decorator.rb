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

    def remit_select_path(item = nil, **opt)
      opt[:id] ||= 'SELECT'
      path_for(item, **opt, action: :remit)
    end

    def remit_path(item = nil, **opt)
      return remit_select_path(item, **opt) if opt[:selected]
      opt[:id] = id_for(item, **opt)
      path_for(item, **opt, action: :remit)
    end

=begin
    def start_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      path_for(item, **opt, action: :start)
    end

    def stop_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      path_for(item, **opt, action: :stop)
    end

    def pause_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      path_for(item, **opt, action: :pause)
    end

    def resume_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
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

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Bulk submission configuration values.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    BULK_SUBMIT_CFG = I18n.t('emma.bulk.submit', default: {}).deep_freeze

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
          entry[:tooltip] %= { item: 'Manifest' } if tip&.include?('%')
          entry[:active] = true
        end
      }.deep_freeze

    # Control icon definitions.
    #
    # @return [Hash{Symbol=>Hash{Symbol=>*}}]
    #
    def control_icons
      super(icons: ICONS)
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
      pairs = opt[:pairs] = model_index_fields.merge(pairs || {})
      outer = opt[:outer] = opt[:outer]&.dup || {}
      unless TABLE_TAGS.include?(opt[:tag])
        outer_class  = css_class_array(*outer[:class])
        need_columns = outer_class.none? { |c| c.start_with?('columns-') }
        append_css!(outer, "columns-#{pairs.size}") if need_columns
      end
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
      super(%i[new edit delete remit])
    end

    # =========================================================================
    # :section: Item forms (edit/delete pages)
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
        when nil, :all then 'Select an existing manifest'   # TODO: I18n
        else                'Select a manifest you created' # TODO: I18n
      end
    end

    # Generate a label for a specific menu entry.
    #
    # @param [Manifest]    item
    # @param [String, nil] label      Override label.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def items_menu_label(item, label: nil)
      label ||= item.menu_label
      label ||= "#{model_item_name(capitalize: true)} #{item.id}"
      ERB::Util.h(label)
    end

    # =========================================================================
    # :section:
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
      desc = 'Use the %s control above to start a new manifest.' # TODO: I18n
      desc = ERB::Util.h(desc) % new_button('Create')
      prepend_css!(opt, css)
      h.page_description_section(desc, **opt)
    end

    # The button displayed when the user has no Manifests to list.
    #
    # @param [String, nil] label
    # @param [String]      css        Characteristic CSS class/selector.
    # @param [Hash]        opt        Passed to #make_link.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def new_button(label = nil, css: '.new-button', **opt)
      label ||= 'Start a new manifest' # TODO: I18n
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
    # initializer
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
      object[field] || EMPTY_VALUE
    end || super
  end

  # ===========================================================================
  # :section: BaseDecorator::Form overrides
  # ===========================================================================

  public

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
  # @return [ActiveRecord::Associations::HasManyAssociation]
  #
  def row_items
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
  # :section: BaseDecorator::Grid overrides
  # ===========================================================================

  public

  def render_grid(**opt)
    opt[:'data-manifest'] = object.id
    super(**opt)
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

  # Basic form controls, including #import_button if appropriate.
  #
  # @param [Hash] opt
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  # @yield [parts] Extend or replace results.
  # @yieldparam [Array<ActiveSupport::SafeBuffer>] parts
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>]
  #
  def form_buttons(**opt)
    opt.reverse_merge!('data-manifest': object.id)
    buttons = super
    buttons << submission_button(**opt)
    buttons << export_button(**opt)
    buttons << import_button(**opt)
    buttons << comm_status(**opt)
    block_given? ? yield(buttons) : buttons
  end

  # Form submit button.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submit_button(**opt)
    opt[:state] ||= (:enabled if object.manifest_items.pending.present?)
    super
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # For use on view templates in place of LayoutHelper#page_heading to support
  # editing the Manifest title.
  #
  # @param [ActiveSupport::SafeBuffer, Array<Symbol>, Symbol, nil] help
  # @param [Hash]                                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def manifest_page_heading(help: nil, **opt)
    name  = object.name

    t_lbl = html_span('Manifest:', class: 'text label')
    t_nam = html_span(name, class: 'text name')
    title = t_lbl << t_nam

    edit  = 'Click to change the title of this manifest' # TODO: I18n
    edit  = html_button('Edit', class: 'title-edit', title: edit)

    input = model_line_editor(pairs: { name: name })

    help  = h.page_heading_help(help)

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
    offline: 'EMMA is offline', # TODO: I18n
    dynamic: '',
  }.freeze

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
    prepend_css!(opt, css, status)
    html_div(opt) do
      STATUS_MESSAGE.map { |type, text| html_span(text, class: type) }
    end
  end

  # ===========================================================================
  # :section: Item forms (remit page)
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
  # :section: Item forms (remit page)
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
    html_div(opt) do
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
    html_span(opt) do
      lbl << val
    end
  end

  # ===========================================================================
  # :section: Item forms (remit page)
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
  # :section: Item forms (remit page)
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
    notice = html_div(notice, n_opt)

    button << notice
  end

  # ===========================================================================
  # :section: Item forms (remit page)
  # ===========================================================================

  public

  # @private
  STATUS_COLUMN_COUNT = ManifestItemDecorator::SUBMIT_COLUMNS.size

  # @private
  STATUS_LABELS = ManifestItemDecorator::SUBMIT_STATUS_LABELS.to_json.freeze

  # submission_status_list
  #
  # @param [Integer, nil] row
  # @param [Integer, nil] index
  # @param [String]       css         Characteristic CSS class/selector.
  # @param [Hash]         opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submission_status_list(
    row:    nil,
    index:  nil,
    css:    '.submission-status-list',
    **opt
  )
    row   ||= 1
    index ||= paginator.first_index

    head = ManifestItemDecorator.submission_status_header(row: row)
    row += 1 if head

    # noinspection RubyMismatchedArgumentType
    rows =
      submit_items.map.with_index(index) do |item, idx|
        decorate(item).submission_status(index: idx, row: (row + idx))
      end

    opt[:role]            ||= 'grid'
    opt[:'data-labels']   ||= STATUS_LABELS
    opt[:'aria-colcount'] ||= STATUS_COLUMN_COUNT
    opt[:'aria-rowcount'] ||= (head ? 1 : 0) + rows.size
    prepend_css!(opt, css)
    html_div(head, *rows, opt)
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

  # ===========================================================================
  # :section: BaseDecorator overrides
  # ===========================================================================

  public

  # Client-side scripting which are supplied via 'assets:precompile'.
  #
  # @param [Hash{Symbol=>*}]
  #
  # @see file:app/assets/javascripts/shared/assets.js.erb  *Emma.Manifest*
  #
  def self.js_properties
    path_properties = {
      upload: upload_path,
      remit:  remit_path(id: JS_ID),
=begin
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
