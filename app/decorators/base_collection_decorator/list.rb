# app/decorators/base_collection_decorator/list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting display of collections of Model instances.
#
module BaseCollectionDecorator::List

  include BaseDecorator::List

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render list items.
  #
  # @param [Integer]       index      Starting index number.
  # @param [Integer]       row        Starting row number.
  # @param [Array<Symbol>] skip       Passed to #list_row.
  # @param [String, nil]   separator  If *nil*, return an array of lines.
  # @param [Hash]          opt        Passed to #list_row.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]  If *separator* set to *nil*.
  # @return [ActiveSupport::SafeBuffer]
  #
  def render(index: 0, row: 1, skip: nil, separator: "\n", **opt)
    opt[:skip] = Array.wrap(skip).compact.uniq
    lines =
      object.map.with_index(index) do |item, idx|
        opt.merge!(index: idx, row: (row + idx), group: item.try(:state_group))
        decorate(item).list_row(**opt)
      end
    separator ? safe_join(lines, separator) : lines
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Text for #no_records_row. # TODO: I18n
  #
  # @type [String]
  #
  NO_RECORDS = 'NO RECORDS'

  # Hidden row that is shown only when no field rows are being displayed.
  #
  # @param [Hash] opt                 Passed to created elements.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def no_records_row(**opt)
    css = '.no-records'
    prepend_css!(opt, css)
    # noinspection RubyMismatchedReturnType
    html_div('', opt) << html_div(NO_RECORDS, opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Options used with template :locals.
  #
  # @type [Array<Symbol>]
  #
  VIEW_TEMPLATE_OPT = %i[list page count row level skip].freeze

  # Generate applied search terms and top/bottom pagination controls.
  #
  # @param [Integer, #to_i, nil] count    Default: *list* size.
  # @param [Integer, #to_i, nil] total    Default: count.
  # @param [Integer, #to_i, nil] records  Number of API records for this page.
  # @param [Integer, #to_i, nil] page     Default: 1.
  # @param [Integer, #to_i, nil] size     Default: #DEFAULT_PAGE_SIZE
  # @param [Integer, #to_i, nil] row      Default: 1.
  # @param [Hash]    opt                  Passed to #list_controls.
  #
  # @return [Array<(ActiveSupport::SafeBuffer,ActiveSupport::SafeBuffer)>]
  #
  def index_controls(
    count:   nil,
    total:   nil,
    records: nil,
    page:    nil,
    size:    nil,
    row:     1,
    **opt
  )
    opt.except!(*VIEW_TEMPLATE_OPT)
    list    = object            || []
    count   = positive(count)   || list.size
    total   = positive(total)   || count
    records = positive(records) || 0
    page    = positive(page)    || 1
    size    = positive(size)    || DEFAULT_PAGE_SIZE
    row   &&= (positive(row) || 1) + 1
    paging  = (page > 1)
    more    = (count < total) || (count == size) || (records == size)
    unit    = list.first&.aggregate? ? 'title' : 'record'

    links   = pagination_controls

    pg_num  = (page_number(page) if paging || more)
    counts  = pagination_count(count, total, unit: unit)
    counts  = html_div(pg_num, counts, class: 'counts')

    ctrls   = list_controls(**opt)

    top_css = css_classes('pagination-top', (row && "row-#{row}"))
    top     = html_div(links, counts, *ctrls, class: top_css)
    bottom  = html_div(links, class: 'pagination-bottom')
    return top, bottom
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Optional controls to modify the display or generation of the item list in
  # the order of display.
  #
  # @type [Array<Symbol>]
  #
  LIST_CONTROL_METHODS = %i[list_results list_filter list_styles]

  # Optional controls to modify the display or generation of the item list in
  # the order of display.
  #
  # @return [Array<Symbol>]
  #
  def list_control_methods
    LIST_CONTROL_METHODS
  end

  # Optional controls to modify the display or generation of the item list.
  #
  # @param [Hash] opt
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def list_controls(**opt)
    list_control_methods.map { |meth| send(meth, **opt) }.compact
  end

  # Optional list style controls in line with the top pagination control.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @see file:javascripts/feature/search-analysis.js *AdvancedFeature*
  #
  def list_styles(**opt)
    # May be overridden by the subclass.
  end

  # Optional list result type controls in line with the top pagination control.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @see file:app/assets/javascripts/controllers/search.js *$mode_menu*
  #
  def list_results(**opt)
    # May be overridden by the subclass.
  end

  # An optional list filter control in line with the top pagination control.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @see file:app/assets/javascripts/feature/records.js *filterPageDisplay()*
  #
  def list_filter(**opt)
    # May be overridden by the subclass.
  end

  # Control the selection of filters displayed by #list_filter.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @see file:app/assets/javascripts/feature/records.js *filterOptionToggle()*
  #
  def list_filter_options(**opt)
    # May be overridden by the subclass.
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
