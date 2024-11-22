# app/decorators/base_collection_decorator/list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting display of collections of Model instances.
#
module BaseCollectionDecorator::List

  include BaseDecorator::List

  include BaseCollectionDecorator::Common
  include BaseCollectionDecorator::Pagination

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render list items.
  #
  # @param [Integer] row              Starting row number.
  # @param [Integer] index            Starting index number.
  # @param [Hash]    opt              Passed to #list_row.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_rows(row: nil, index: nil, **opt)
    trace_attrs!(opt, __method__)
    row   ||= 1
    index ||= paginator.first_index
    lines =
      object.map.with_index(index) do |item, idx|
        # noinspection RailsParamDefResolve
        g = item.try(:state_group)
        decorate(item).list_row(**opt, index: idx, row: (row + idx), group: g)
      end
    safe_join(lines, DEFAULT_ELEMENT_SEPARATOR)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Hidden row that is shown only when no field rows are being displayed.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to created elements.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @note Currently unused.
  # :nocov:
  def no_records_row(css: '.no-records', **opt)
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css)
    space  = html_div(**opt)
    notice = html_div(**opt) { config_term(:list, :no_records) }
    space << notice
  end
  # :nocov:

  # ===========================================================================
  # :section: Index page support
  # ===========================================================================

  public

  # Options used with template :locals.
  #
  # @type [Array<Symbol>]
  #
  VIEW_TEMPLATE_OPT = %i[list page count row level skip].freeze

  # Generate applied search terms and top/bottom pagination controls.
  #
  # @param [Integer] row              Starting row number.
  # @param [Hash]    opt              Passed to #list_controls.
  #
  # @return [Array(ActiveSupport::SafeBuffer,ActiveSupport::SafeBuffer)]
  #
  def index_controls(row: nil, **opt)
    trace_attrs!(opt, __method__)
    list   = opt.delete(:list) || object || []
    unit   = opt.delete(:unit)

    ctrls  = list_controls(**opt)
    links  = pagination_controls
    counts = page_count_and_number(list: list, unit: unit, **opt)

    top    = pagination_top(links, counts, *ctrls, row: row)
    bottom = pagination_bottom(links)
    return top, bottom
  end

  # ===========================================================================
  # :section: Index page support
  # ===========================================================================

  public

  # Optional controls to modify the display or generation of the item list in
  # the order of display.
  #
  # @type [Array<Symbol>]
  #
  LIST_CONTROL_METHODS = %i[list_results list_filter list_styles].freeze

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
    trace_attrs!(opt, __method__)
    list_control_methods.map { send(_1, **opt) }.compact
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
    may_be_overridden # if the subclass is configured for search analysis
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
    may_be_overridden
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
    may_be_overridden
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
    may_be_overridden
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
