# app/helpers/model_helper/list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting display of Model instances (both database
# items and API messages).
#
module ModelHelper::List

  include ModelHelper::Fields

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Displayed in place of a results list.
  #
  # @type [String]
  #
  NO_RESULTS = 'NONE FOUND' # TODO: I18n

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render field/value pairs.
  #
  # @param [Model, Hash, nil]    item
  # @param [String, Symbol, nil] model        Default: `params[:controller]`.
  # @param [String, Symbol, nil] action       Default: `params[:action]`.
  # @param [Hash, nil]           pairs        Except for #render_pair options.
  # @param [Integer, nil]        row_offset   Def: 0.
  # @param [String, nil]         separator    Def: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Hash]                opt
  # @param [Proc]                block        Passed to #field_values.
  #
  # @option opt [Integer] :index              Offset to make unique element IDs
  #                                             passed to #render_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_field_values(
    item,
    model:      nil,
    action:     nil,
    pairs:      nil,
    row_offset: nil,
    separator:  DEFAULT_ELEMENT_SEPARATOR,
    **opt,
    &block
  )
    return ''.html_safe unless item

    opt[:row]   = row_offset || 0
    opt[:model] = Model.for(model || item) || params[:controller]&.to_sym

    value_opt = opt.slice(:model, :index, :min_index, :max_index, :no_format)
    fp_opt    = opt.slice(:model).merge!(action: action, pairs: pairs)

    field_pairs(item, **fp_opt, &block).map { |field, prop|
      opt[:row] += 1
      value  = render_value(item, prop[:value], **value_opt)
      levels = field_scopes(field).presence
      rp_opt = levels ? append_classes(opt, levels) : opt
      render_pair(prop[:label], value, prop: prop, **rp_opt)
    }.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair.
  #
  # @param [String, Symbol, nil] label
  # @param [*]                   value
  # @param [Hash, nil]           prop       Default: from field/model.
  # @param [Symbol, nil]         field
  # @param [Symbol, nil]         model      Default: `params[:controller]`
  # @param [String, Integer]     index      Offset to make unique element IDs.
  # @param [Integer, nil]        row        Display row.
  # @param [String, nil]         separator  Between parts if *value* is array.
  # @param [Hash]                opt        Passed to each #html_div except:
  #
  # @option opt [Symbol, Array<Symbol>] :no_format
  #
  # @return [ActiveSupport::SafeBuffer]     HTML label and value elements.
  # @return [nil]                           If *value* is blank.
  #
  # == Usage Notes
  # If *label* is HTML then no ".field-???" class is included for the ".label"
  # and ".value" elements.
  #
  def render_pair(
    label,
    value,
    prop:      nil,
    field:     nil,
    model:     nil,
    index:     nil,
    row:       1,
    separator: nil,
    **opt
  )
    return if value.blank?

    model ||= params[:controller]
    prop  ||= Field.configuration_for(field, model)
    field ||= prop[:field]

    # Pre-process label to derive names and identifiers.
    base = model_html_id(field || label)
    type = "field-#{base}"
    v_id = type.dup
    l_id = +"label-#{base}"
    [v_id, l_id].each { |id| id << "-#{index}" } if index

    # Extract range values.
    value = value.content if value.is_a?(Field::Type)

    # Format the content of certain fields.
    lines = nil
    unless Array.wrap(opt.delete(:no_format)).include?(field)
      # noinspection RubyMismatchedParameterType
      # noinspection RubyCaseWithoutElseBlockInspection
      case field
        when :dc_description
          value = lines = format_description(value)
        when :rem_comments, :s_accessibilitySummary
          value = lines = format_multiline(value)
        when :emma_lastRemediationNote, :rem_remediationComments
          value = lines = format_multiline(value)
        when :dc_identifier, :dc_relation
          value = mark_invalid_identifiers(value)
        when :dc_language
          value = mark_invalid_languages(value, code: (model != :search))
      end
    end

    # Adjust field properties.
    enum  = prop[:type].is_a?(Class)
    delta = {}
    delta[:type]  = 'textarea' if lines&.many? && !enum
    delta[:array] = true       if enum && !prop[:array]
    # noinspection RubyNilAnalysis
    prop = prop.merge(delta)   if delta.present?

    # Pre-process value(s).
    if prop[:array]
      value = value.is_a?(Array) ? value.dup : [value]
      value.map!.with_index(1) { |v, i| html_div(v, class: "item-#{i}") }
      value = safe_join(value, separator)
    elsif value.is_a?(Array)
      value = safe_join(value, (separator || HTML_BREAK))
    end

    # Create a help icon control if applicable.
    if (help = prop[:help]).present?
      replace = topic = nil
      if field == :emma_retrievalLink
        # noinspection RubyMismatchedParameterType
        url     = extract_url(value)
        topic   = url_repository(url, default: !application_deployed?)
        replace = help.is_a?(Array) && (help.size > 1)
      end
      help = replace ? (help[0...-1] << topic) : [*help, topic] if topic
      help = help_popup(*help)
    end

    # Add tooltip if configured.
    opt[:title] = prop[:tooltip] unless field == :dc_title

    # Option settings for both label and value.
    status   = nil
    status ||= ('array'     if prop[:array] && enum)
    status ||= ('list'      if prop[:array])
    status ||= ('enum'      if enum)
    status ||= ('textbox'   if prop[:type] == 'textarea')
    status ||= ('numeric'   if prop[:type] == 'number')
    status ||= ('hierarchy' if prop[:type] == 'json')
    status ||= prop[:type]
    prepend_classes!(opt, "row-#{row}", type, status)

    # Label and label HTML options.
    l_opt = prepend_classes(opt, 'label').merge!(id: l_id)
    label = prop[:label] || label
    unless label.is_a?(ActiveSupport::SafeBuffer)
      label ||= labelize(field)
      label = html_span(label, class: 'text')
    end
    label += help if help.present?
    label = html_div(label, l_opt)

    # Value and value HTML options.
    v_opt = prepend_classes(opt, 'value').merge!(id: v_id)
    v_opt[:'aria-labelledby'] = l_id
    value = html_div(value, v_opt)

    # noinspection RubyMismatchedReturnType
    label << value
  end

  # An indicator that can be used to stand for an empty list.
  #
  # @param [String, nil] message      Default: #NO_RESULTS.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_empty_value(message = nil, **)
    # noinspection RubyMismatchedReturnType
    render_pair(nil, (message || NO_RESULTS))
  end

  # Transform a field value for HTML rendering.
  #
  # @param [Model, Hash, nil]    item
  # @param [*]                   value
  # @param [String, Symbol, nil] model  If provided, a model-specific method
  #                                       will be invoked instead.
  # @param [Hash]                opt    Passed to render method.
  #
  # @return [Any]   HTML or scalar value.
  # @return [nil]   If *value* was *nil* or *item* resolved to *nil*.
  #
  def render_value(item, value, model: nil, **opt)
    model = Model.for(model) unless model.is_a?(Symbol)
    if model && respond_to?((meth = "#{model}_render_value"))
      send(meth, item, value, **opt)
    elsif value.is_a?(Symbol)
      execute(item, value, **opt)
    else
      value.is_a?(FalseClass) ? value.to_s : value
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Attempt to interpret *method* as an *item* method or as a method defined
  # in the current context.
  #
  # @param [Model, Hash, nil]  item
  # @param [String, Symbol, *] m
  # @param [Hash]              opt    Options (used only if appropriate).
  #
  # @return [Any]                     HTML or scalar value.
  # @return [nil]                     If executed method returned *nil*.
  #
  def execute(item, m, **opt)
    if item.respond_to?(m)
      item.method(m).arity.zero? ? item.send(m) : item.send(m, **opt)
    elsif respond_to?(m)
      args = method(m).arity
      if args.zero?
        send(m)
      elsif args.positive?
        send(m, item)
      elsif args == -1
        send(m, **opt)
      elsif args < -1
        send(m, item, **opt)
      end
    end
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

  # Method options which are processed internally and not passed on as HTML
  # options.
  #
  # @type [Array<Symbol>]
  #
  ITEM_ENTRY_OPT = %i[index offset group row level skip].freeze

  # Generate applied search terms and top/bottom pagination controls.
  #
  # @param [Array, nil]          list   Default: #page_items.
  # @param [Integer, #to_i, nil] count  Default: *list* size.
  # @param [Integer, #to_i, nil] total  Default: count.
  # @param [Integer, #to_i, nil] page
  # @param [Integer, #to_i, nil] size   Default: #page_size.
  # @param [Integer, #to_i, nil] row    Default: 1.
  # @param [Hash]    opt                Passed to #page_filter.
  #
  # @return [(ActiveSupport::SafeBuffer,ActiveSupport::SafeBuffer)]
  #
  def index_controls(
    list:   nil,
    count:  nil,
    total:  nil,
    page:   nil,
    size:   nil,
    row:    1,
    **opt
  )
    opt.except!(*VIEW_TEMPLATE_OPT)
    items   = list            || page_items
    unit    = items&.first&.aggregate? ? 'title' : 'record'
    count   = positive(count) || items.size
    total   = positive(total) || count
    page    = positive(page)  || 1
    size    = positive(size)  || page_size
    row   &&= 1 + (positive(row) || 1)
    paging  = (page > 1)
    more    = (count < total) || (count == size)
    links   = pagination_controls
    counts  = []
    counts << page_number(page) if paging || more
    counts << pagination_count(count, total, unit: unit)
    counts  = html_div(*counts, class: 'counts')
    styles  = page_styles(**opt)
    filter  = page_filter(**opt)
    top_css = css_classes('pagination-top', (row && "row-#{row}"))
    top     = html_div(links, counts, styles, filter, class: top_css)
    bottom  = html_div(links, class: 'pagination-bottom')
    return top, bottom
  end

  # Optional page style controls in line with the top pagination control.
  #
  # @param [Hash] opt                 Passed to model-specific method except:
  #
  # @option opt [String, Symbol] :model   Default: `params[:controller]`
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @see SearchHelper#search_page_styles
  #
  def page_styles(**opt)
    model = opt.delete(:model) || params[:controller]
    try("#{model}_#{__method__}", **opt)
  end

  # An optional page filter control in line with the top pagination control.
  #
  # @param [Hash] opt                 Passed to model-specific method except:
  #
  # @option opt [String, Symbol] :model   Default: `params[:controller]`
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @see UploadHelper#upload_page_filter
  #
  def page_filter(**opt)
    model = opt.delete(:model) || params[:controller]
    try("#{model}_#{__method__}", **opt)
  end

  # Render an element containing the ordinal position of an entry within a list
  # based on the provided *offset* and *index*.
  #
  # @param [Model]        item
  # @param [Integer]      index       Index number.
  # @param [Integer, nil] offset      Default: `#page_offset`.
  # @param [Integer, nil] level       Heading tag level (@see #html_tag).
  # @param [String, nil]  group       Sets :'data-group' for outer <div>.
  # @param [Integer, nil] row
  # @param [Hash]         opt         Passed to inner #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* or *index* is *nil*.
  #
  # @yield [index,offset] To supply additional parts within .number element.
  # @yieldparam  [Integer] index      The effective index number.
  # @yieldparam  [Integer] offset     The effective page offset.
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def list_item_number(
    item,
    index:,
    offset: nil,
    level:  nil,
    group:  nil,
    row:    nil,
    **opt
  )
    css_selector = '.number'
    return unless item && index
    opt.except!(*ITEM_ENTRY_OPT)
    index  = non_negative(index)
    row    = positive(row)
    offset = offset&.to_i || page_offset
    parts  = []

    # Label visible only to screen-readers:
    label = index ? 'Entry ' : 'Empty results' # TODO: I18n
    parts << html_span(label, class: 'sr-only')

    # Visible item number value:
    value = index ? "#{offset + index + 1}" : ''
    parts << html_span(value, class: 'value')

    # Additional elements supplied by the block:
    parts += Array.wrap(yield(index, offset)) if block_given?

    # Wrap parts in a container for group positioning:
    inner_opt = prepend_classes(opt, 'container')
    container = html_tag(level, parts, inner_opt)

    # Wrap the container in the actual number grid element.
    outer_opt = { class: css_classes(css_selector) }
    append_classes!(outer_opt, "row-#{row}") if row
    outer_opt[:'data-group']    = group      if group
    outer_opt[:'data-title_id'] = item.try(:emma_titleId)
    html_div(container, outer_opt)
  end

  # Render a single entry for use within a list of items.
  #
  # @param [Model, nil]     item
  # @param [String, Symbol] model
  # @param [Hash, nil]      pairs         Label/value pairs.
  # @param [Symbol]         render        Default: #render_field_values.
  # @param [Hash]           opt           Passed to the render method.
  # @param [Proc]           block         Passed to the render method.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def model_list_item(item, model:, pairs: nil, render: nil, **opt, &block)
    opt[:model]  = model ||= Model.for(item)
    css_selector = ".#{model}-list-item"
    html_opt     = { class: css_classes(css_selector) }
    row          = positive(opt[:row])
    append_classes!(html_opt, "row-#{row}") if row
    append_classes!(html_opt, 'empty')      if (id = item).nil?
    id &&= item.try(:submission_id) || item.try(:identifier) || hex_rand
    html_opt[:id]                        = "#{model}-#{id}" if id
    html_opt[:'data-group']= opt[:group] = item.try(:state_group)
    html_opt[:'data-title_id']           = item.try(:emma_titleId)
    html_opt[:'data-normalized_title']   = item.try(:normalized_title)
    html_opt[:'data-sort_date']          = item.try(:emma_sortDate)
    html_opt[:'data-pub_date']           = item.try(:emma_publicationDate)
    html_opt[:'data-rem_date']           = item.try(:rem_remediationDate)
    html_opt[:'data-item_score']         = item.try(:total_score, precision: 2)
    html_div(html_opt) do
      render = :render_empty_value  if item.nil?
      render = :render_field_values if render.nil?
      send(render, item, pairs: pairs, **opt, &block)
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render a metadata listing of a model instance.
  #
  # @param [Model]          item
  # @param [Hash, nil]      pairs         Label/value pairs.
  # @param [Hash]           opt           Passed to #render_field_values.
  # @param [Proc]           block         Passed to #render_field_values.
  #
  # @option opt [Symbol] :model           Default: `Model#for(item)`.
  # @option opt [String] :class           Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If *item* is blank.
  #
  def model_details(item, pairs: nil, **opt, &block)
    return if item.blank?
    opt[:model] ||= Model.for(item)
    css_selector  = ".#{opt[:model]}-details"
    classes       = css_classes(css_selector, opt.delete(:class))
    html_div(class: classes) do
      render_field_values(item, pairs: pairs, **opt, &block)
    end
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
