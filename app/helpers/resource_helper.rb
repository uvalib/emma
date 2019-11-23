# app/helpers/resource_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting controllers that manipulate specific types of items.
#
module ResourceHelper

  def self.included(base)
    __included(base, '[ResourceHelper]')
  end

  include GenericHelper
  include ParamsHelper
  include PaginationHelper
  include BookshareHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Separator for a list formed by HTML elements.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  DEFAULT_ELEMENT_SEPARATOR = "\n".html_safe.freeze

  # Displayed in place of a results list.
  #
  # @type [String]
  #
  NO_RESULTS = 'NONE FOUND' # TODO: I18n

  # Creator field categories.
  #
  # @type [Array<Symbol>]
  #
  CREATOR_FIELDS =
    Bs::Shared::TitleMethods::CREATOR_TYPES.map(&:to_sym).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<Symbol>]
  ITEM_LINK_OPTIONS =
    %i[label no_link path path_method tooltip scope controller].freeze

  # Create a link to the details show page for the given item.
  #
  # @yield [terms] Supplies a path based on *terms* to use instead of *path*.
  # @yieldparam  [String] terms
  # @yieldreturn [String]
  #
  # @param [Api::Record]         item
  # @param [Symbol, String, nil] label    Default: `item.label`.
  # @param [Proc, String, nil]   path     From block if not provided here.
  # @param [Hash]                opt      Passed to #make_link except for:
  #
  # @option opt [Boolean]        :no_link
  # @option opt [String]         :tooltip
  # @option opt [String]         :label
  # @option opt [String]         :path
  # @option opt [Symbol]         :path_method
  # @option opt [Symbol, String] :scope
  # @option opt [Symbol, String] :controller
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def item_link(item, label = nil, path = nil, **opt)
    opt, html_opt = partition_options(opt, *ITEM_LINK_OPTIONS)
    label = opt[:label] || label || :label
    label = item.send(label) if label.is_a?(Symbol)
    if opt[:no_link]
      content_tag(:span, label, html_opt)
    else
      path = yield(label) if block_given?
      path = opt[:path] || opt[:path_method] || path
      path = path.call(item, label) if path.is_a?(Proc)
      unless (html_opt[:title] ||= opt[:tooltip])
        scope = opt[:scope] || opt[:controller]
        scope ||= request_parameters[:controller]
        scope &&= "emma.#{scope}.show.tooltip"
        html_opt[:title] = I18n.t(scope, default: '')
      end
      # noinspection RubyYardParamTypeMatch
      make_link(label, path, html_opt)
    end
  end

  # @type [Array<Symbol>]
  SEARCH_LINKS_OPTIONS =
    %i[field method method_opt separator link_method].freeze

  # Item terms as search links.
  #
  # Items in returned in two separately sorted groups: actionable links (<a>
  # elements) followed by items which are not linkable (<span> elements).
  #
  # @param [Api::Record] item
  # @param [Symbol, nil] field          Default: :title
  # @param [Hash]        opt            Passed to :link_method except for:
  #
  # @option opt [Symbol] :field
  # @option opt [Symbol] :method
  # @option opt [Hash]   :method_opt    Passed to *method* call.
  # @option opt [String] :separator     Default: #DEFAULT_ELEMENT_SEPARATOR
  # @option opt [Symbol] :link_method   Default: :search_link
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If item method cannot be determined.
  #
  def search_links(item, field = nil, **opt)

    method = opt[:method]
    field  = (opt[:field] || field || :title).to_s
    case field
      when 'creator_list'
        method ||= field.to_sym
        field    = :author
      when /_list$/
        method ||= field.to_sym
        field    = field.delete_suffix('_list').to_sym
      else
        method ||= field.pluralize.to_sym
        field    = field.to_sym
    end
    __debug { "#{__method__}: item.#{method} invalid" } unless item.respond_to?(method)
    return unless item.respond_to?(method)

    opt, html_opt = partition_options(opt, *SEARCH_LINKS_OPTIONS)
    separator   = opt[:separator]   || DEFAULT_ELEMENT_SEPARATOR
    link_method = opt[:link_method] || :search_link
    check_link  = !opt.key?(:no_link)

    method_opt = (opt[:method_opt].presence if item.method(method).arity >= 0)
    values = method_opt ? item.send(method, **method_opt) : item.send(method)
    Array.wrap(values)
      .map { |record|
        link_opt = html_opt
        if check_link
          # noinspection RubyCaseWithoutElseBlockInspection
          no_link =
            case field
              when :categories then !record.bookshare_category
            end
          link_opt = link_opt.merge(no_link: no_link) if no_link
        end
        send(link_method, record, field, **link_opt)
      }
      .compact
      .sort_by { |html_element|
        term   = html_element.to_s
        prefix = term.start_with?('<a') ? '' : 'ZZZ'
        term.sub(/^<[^>]+>/, prefix)
      }
      .uniq
      .join(separator).html_safe

  end

  # @type [Array<Symbol>]
  SEARCH_LINK_OPTIONS = %i[field all_words no_link scope controller].freeze

  # Create a link to the search results index page for the given term(s).
  #
  # @param [Api::Record, String] terms
  # @param [Symbol, nil]         field        Default: :title
  # @param [Hash]                opt          Passed to #make_link except for:
  #
  # @option opt [Symbol]         :field
  # @option opt [Boolean]        :all_words
  # @option opt [Boolean]        :no_link
  # @option opt [Symbol, String] :scope
  # @option opt [Symbol, String] :controller
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                             If no *terms* were provided.
  #
  def search_link(terms, field = nil, **opt)
    terms = terms.to_s.strip.presence or return
    opt, html_opt = partition_options(opt, *SEARCH_LINK_OPTIONS)
    field = opt[:field] || field || :title

    # Generate the link label.
    ftype = field_category(field)
    label = (ftype == :language) && ISO_639.find(terms)&.english_name || terms
    terms = terms.sub(/\s+\([^)]+\)$/, '') if CREATOR_FIELDS.include?(ftype)

    # If this instance should not be rendered as a link, return now.
    return content_tag(:span, label, **html_opt) if opt[:no_link]

    # Otherwise, wrap the terms phrase in quotes unless directed to handled
    # each word of the phrase separately.
    ctrl   = opt[:scope] || opt[:controller] || request_parameters[:controller]
    phrase = !opt[:all_words]
    terms  = %Q("#{terms}") if phrase

    # Create a tooltip unless one was provided.
    unless (html_opt[:title] ||= opt[:tooltip])
      scope = ctrl && "emma.#{ctrl}.index.tooltip"
      tip_terms = +"#{field} "
      tip_terms <<
        if phrase
          terms
        else
          words = terms.split(/\s/).compact.map { |t| %Q("#{t}") }
          (words.size > 1) ? ('containing ' + words.join(', ')) : words.first
        end
      html_opt[:title] = I18n.t(scope, terms: tip_terms, default: '')
    end

    # Generate the search path.
    search = Array.wrap(field).map { |f| [f, terms] }.to_h
    search[:controller] = ctrl
    search[:action]     = :index
    search[:only_path]  = true
    path = url_for(search)

    # noinspection RubyYardParamTypeMatch
    make_link(label, path, html_opt)
  end

  # Create record links to an external target or via the internal API interface
  # endpoint.
  #
  # @param [Api::Record, Array<String>, String] links
  # @param [Hash] opt                 Passed to #make_link except for:
  #
  # @option opt [Boolean] :no_link
  # @option opt [String]  :separator  Default: #DEFAULT_ELEMENT_SEPARATOR.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def record_links(links, **opt)
    opt, html_opt = partition_options(opt, :no_link, :separator)
    prepend_css_classes!(html_opt, 'external-link')
    separator = opt[:separator] || DEFAULT_ELEMENT_SEPARATOR
    no_link   = opt[:no_link]
    links = links.record_links if links.respond_to?(:record_links)
    Array.wrap(links).map { |link|
      next if link.blank?
      path = (api_explorer_url(link) unless no_link)
      if path.present? && !path.match?(/[{}]/)
        make_link(link, path, html_opt)
      else
        content_tag(:div, link, class: 'non-link')
      end
    }.compact.join(separator).html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Field/value pairs.
  #
  # If *pairs* is not provided (as a parameter or through a block) then
  # `item#field_names` is used.  If no block is provided and *pairs* is present
  # then this function simply returns *pairs* as-is.
  #
  # @yield [item] Supplies additional field/value pairs based on *item*.
  # @yieldparam  [Api::Record] item   The supplied *item* parameter.
  # @yieldreturn [Hash]               Result will be merged into *pairs*.
  #
  # @param [Api::Record] item
  # @param [Hash, nil]   pairs
  #
  # @return [Hash]
  #
  def field_values(item, pairs = nil)
    if block_given?
      yield(item).reverse_merge(pairs || {})
    elsif pairs.is_a?(Hash)
      pairs
    else
      item.field_names.map { |f| [f.to_s.titleize.to_sym, f] }.to_h
    end
  end

  # Render field/value pairs.
  #
  # @param [Api::Record]    item
  # @param [String, Symbol] model
  # @param [Hash]           pairs       Except for #render_pair options.
  # @param [Integer]        row_offset  Default: 0.
  # @param [String]         separator   Default: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Proc]           block       Passed to #field_values.
  #
  # @option pairs [Integer] :index      Offset for making unique element IDs)
  #                                       passed to #render_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_field_values(
    item,
    model:      nil,
    pairs:      nil,
    row_offset: nil,
    separator:  DEFAULT_ELEMENT_SEPARATOR,
    &block
  )
    pairs = field_values(item, pairs, &block)
    opt, pairs = partition_options(pairs, :index, :row) # Discard :row
    opt[:row] = row_offset || 0
    # noinspection RubyNilAnalysis
    pairs.map { |label, value|
      opt[:row] += 1
      value = render_value(item, value, model: model)
      render_pair(label, value, **opt) if value
    }.compact.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair.
  #
  # @param [String, Symbol] label
  # @param [Object]         value
  # @param [Integer]        index       Offset for making unique element IDs.
  # @param [Integer]        row         Display row.
  # @param [String]         separator   Inserted between elements if *value* is
  #                                       an array.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If *value* is blank.
  #
  # == Usage Notes
  # If *label* is HTML then no ".field-???" class is included for the ".label"
  # and ".value" elements.
  #
  def render_pair(label, value, index: nil, row: 1, separator: nil)
    return if value.blank?
    css = %W(row-#{row})
    id  = nil

    # Label and label HTML options.
    unless label.is_a?(ActiveSupport::SafeBuffer)
      type  = label ? "field-#{label}"   : 'field-None'
      id    = index ? "#{type}-#{index}" : type
      label = labelize(label)
      css << type
    end
    l_opt = append_css_classes('label', *css)
    label = content_tag(:div, label, l_opt)

    # Value and value HTML options.
    if value.is_a?(Array)
      i = 0
      value = value.map { |v| content_tag(:div, v, class: "item-#{i += 1}") }
      value = safe_join(value, separator)
      css << 'array'
    end
    v_opt = append_css_classes('value', *css)
    v_opt[:id] = id if id
    value = content_tag(:div, value, v_opt)

    # noinspection RubyYardReturnMatch
    label << value
  end

  # An indicator that can be used to stand for an empty list.
  #
  # @param [String, nil] message      Default: #NO_RESULTS.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_empty_value(message = NO_RESULTS)
    render_pair(nil, message)
  end

  # Transform a field value for HTML rendering.
  #
  # @param [Api::Record]    item
  # @param [Object]         value
  # @param [String, Symbol] model     If provided, a model-specific method will
  #                                     be invoked instead.
  #
  # @return [Object]
  #
  def render_value(item, value, model: nil)
    # noinspection RubyAssignmentExpressionInConditionalInspection
    if model && respond_to?(model_method = "#{model}_render_value")
      send(model_method, item, value)
    elsif value.is_a?(Symbol)
      case field_category(value)
        when :author      then author_links(item)
        when :bookshareId then bookshare_link(item)
        when :category    then category_links(item)
        when :composer    then composer_links(item)
        when :country     then country_links(item)
        when :cover       then cover_image(item)
        when :cover_image then cover_image(item)
        when :creator     then creator_links(item)
        when :editor      then editor_links(item)
        when :fmt         then format_links(item)
        when :format      then format_links(item)
        when :language    then language_links(item)
        when :link        then record_links(item)
        when :narrator    then narrator_links(item)
        when :numImage    then number_with_delimiter(item.image_count)
        when :numPage     then number_with_delimiter(item.page_count)
        when :thumbnail   then thumbnail(item)
        else                   execute(item, value)
      end
    elsif value.is_a?(FalseClass)
      value.to_s
    else
      value
    end
  end

  # The type of named field regardless of pluralization or presence of a
  # "_list" suffix.
  #
  # @param [Symbol, String, *] name
  #
  # @return [Symbol]
  #
  def field_category(name)
    name.to_s.delete_suffix('_list').singularize.to_sym
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Attempt to interpret *method* as an *item* method or as a method defined
  # in the current context.
  #
  # @param [Api::Record]       item
  # @param [String, Symbol, *] m
  # @param [Hash]              opt    Options (used only if appropriate).
  #
  # @return [Object]
  # @return [nil]
  #
  def execute(item, m, **opt)
    if item.respond_to?(m)
      item.method(m).arity.zero? ? item.send(m) : item.send(m, **opt)
    elsif respond_to?(m)
      args = method(m).arity
      if args.zero?
        send(m)
      elsif args > 0
        send(m, item)
      elsif args == -1
        send(m, **opt)
      elsif args < -1
        send(m, item, **opt)
      end
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render an item metadata listing.
  #
  # @param [Api::Record]    item
  # @param [String, Symbol] model
  # @param [Hash, nil]      pairs     Label/value pairs.
  # @param [Proc]           block     Passed to #render_field_values.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def item_details(item, model, pairs = nil, &block)
    return if item.blank?
    content_tag(:div, class: "#{model}-details") do
      render_field_values(item, model: model, pairs: pairs, &block)
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  ITEM_ENTRY_OPT = %i[index offset level row skip].freeze

  # Active search terms.
  #
  # @param [Hash, nil]                  pairs   Default: `#url_parameters`.
  # @param [Symbol, Array<Symbol>, nil] only
  # @param [Symbol, Array<Symbol>, nil] except
  #
  # @return [Hash{String=>String}]
  #
  def search_terms(pairs = nil, only: nil, except: nil)
    only    = Array.wrap(only).presence
    except  = Array.wrap(except) + %i[offset start limit api_key]
    pairs &&= pairs.dup if only || except
    pairs ||= url_parameters
    pairs.slice!(*only)    if only
    pairs.except!(*except) if except
    pairs.map { |k, v|
      count = v.is_a?(Array) ? v.size : 1
      field = labelize(k, count)
      value = strip_quotes(v)
      [field, %Q("#{value}")]
    }.to_h
  end

  # A control displaying the currently-applied search terms in the current
  # scope (by default).
  #
  # @param [Hash, nil] term_list      Default: `#search_terms`.
  # @param [Hash]      opt            Passed to the innermost :content_tag.
  #
  # @option opt [Integer] :row        Display row (default: 1)
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def applied_search_terms(term_list = nil, **opt)
    term_list ||= search_terms
    opt, term_opt = partition_options(opt, :row)
    row = positive(opt[:row]) || 1
    html_opt = { class: "applied-search-terms row-#{row}" }
    append_css_classes!(html_opt, 'invisible') if term_list.blank?
    content_tag(:div, html_opt) do
      if term_list.present?
        prepend_css_classes!(term_opt, 'term')
        leader = 'Search terms:' # TODO: I18n
        leader = content_tag(:div, leader, class: 'label')
        tm_sep = content_tag(:span, ';', class: 'term-separator')
        terms  =
          term_list.map { |field, value|
            label = content_tag(:span, field, class: 'field')
            sep   = content_tag(:span, ':',   class: 'separator')
            value = content_tag(:span, value, class: 'value')
            content_tag(:div, (label + sep + value), term_opt)
          }.join(tm_sep).html_safe
        content_tag(:div, class: 'search-terms') { leader + terms }
      end
    end
  end

  # Generate applied search terms and top/bottom pagination controls.
  #
  # @param [Hash, nil] terms          Default: `#search_terms`.
  # @param [Integer]   count          Default: `#total_items`.
  # @param [Integer]   row
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def index_controls(terms = nil, count: nil, row: 1)
    page_controls = pagination_controls
    result = []
    result << applied_search_terms(terms, row: row)
    result <<
      content_tag(:div, class: "pagination-top row-#{row += 1}") do
        page_controls + pagination_count(count)
      end
    result << content_tag(:div, class: 'pagination-bottom') { page_controls }
  end

  # Render an element containing the ordinal position of an entry within a list
  # based on the provided *offset* and *index*.
  #
  # @param [Api::Record] item
  # @param [Hash]        opt          Passed to #content_tag except for:
  #
  # @option [Integer] :index          Required index number.
  # @option [Integer] :offset         Default: `#page_offset`.
  # @option [Integer] :level          Heading tag level; if missing a '<div>'
  #                                     is produced rather than '<h1>', etc.
  # @option [Object]  :skip           Ignored.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_entry_number(item, **opt)
    opt, html_opt = partition_options(opt, *ITEM_ENTRY_OPT)
    return unless item && opt[:index]
    prepend_css_classes!(html_opt, 'number')
    row   = positive(opt[:row])
    level = positive(opt[:level])
    tag   = level ? "h#{level}" : 'div'
    append_css_classes!(html_opt, 'clear-default-styling') if level
    append_css_classes!(html_opt, "row-#{row}")            if row
    content_tag(tag, html_opt) do
      index  = non_negative(opt[:index])
      offset = opt[:offset]&.to_i || page_offset
      label  = index ? 'Entry ' : 'Empty results' # TODO: I18n
      value  = index ? "#{offset + index + 1}" : ''
      content_tag(:span, label, class: 'sr-only') << value
    end
  end

  # Render a single entry for use within a list of items.
  #
  # @param [Api::Record]    item
  # @param [String, Symbol] model
  # @param [Hash, nil]      pairs     Label/value pairs.
  # @param [Proc]           block     Passed to #render_field_values.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def item_list_entry(item, model, pairs = nil, &block)
    html_opt = { class: "#{model}-list-entry" }
    # noinspection RubyYardParamTypeMatch
    row = positive(pairs && pairs[:row])
    append_css_classes!(html_opt, "row-#{row}") if row
    if item.nil?
      append_css_classes!(html_opt, 'empty')
    elsif item.respond_to?(:identifier)
      html_opt[:id] = "#{model}-#{item.identifier}"
    end
    content_tag(:div, html_opt) do
      if item
        render_field_values(item, model: model, pairs: pairs, &block)
      else
        render_empty_value
      end
    end
  end

end

__loading_end(__FILE__)
