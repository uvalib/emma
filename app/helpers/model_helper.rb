# app/helpers/model_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting controllers that manipulate received items.
#
module ModelHelper

  def self.included(base)
    __included(base, '[ModelHelper]')
  end

  include Emma::Common
  include Emma::Json
  include Emma::Unicode
  include PaginationHelper
  include SearchTermsHelper

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

  # Field value used to explicitly indicate missing data.
  #
  # @type [String]
  #
  EMPTY_VALUE = EN_DASH

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
  # @param [Model] item
  # @param [Hash]  opt                Passed to #make_link except for:
  #
  # @option opt [Boolean]        :no_link       If *true*, create a <span>.
  # @option opt [String]         :tooltip
  # @option opt [String, Symbol] :label         Default: `item.label`.
  # @option opt [String, Proc]   :path          Default: from block.
  # @option opt [Symbol]         :path_method
  # @option opt [String, Symbol] :scope
  # @option opt [String, Symbol] :controller
  #
  # @return [ActiveSupport::SafeBuffer]   HTML link or text element.
  #
  # @yield [terms] To supply a path based on *terms* to use instead of *path*.
  # @yieldparam  [String] terms
  # @yieldreturn [String]
  #
  def item_link(item, **opt)
    opt, html_opt = partition_options(opt, *ITEM_LINK_OPTIONS)
    label = opt[:label] || :label
    label = item.send(label) if label.is_a?(Symbol)
    if opt[:no_link]
      html_span(label, html_opt)
    else
      path = (yield(label) if block_given?) || opt[:path] || opt[:path_method]
      path = path.call(item, label) if path.is_a?(Proc)
      unless (html_opt[:title] ||= opt[:tooltip])
        scope = opt[:scope] || opt[:controller]
        scope ||= request_parameters[:controller]
        scope &&= "emma.#{scope}.show.tooltip"
        html_opt[:title] = I18n.t(scope, default: '')
      end
      # noinspection RubyYardParamTypeMatch
      make_link(label, path, **html_opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<Symbol>]
  SEARCH_LINKS_OPTIONS =
    %i[field method method_opt separator link_method].freeze

  # Item terms as search links.
  #
  # Items in returned in two separately sorted groups: actionable links (<a>
  # elements) followed by items which are not linkable (<span> elements).
  #
  # @param [Model] item
  # @param [Hash]  opt                  Passed to :link_method except for:
  #
  # @option opt [Symbol] :field
  # @option opt [Symbol] :method
  # @option opt [Hash]   :method_opt    Passed to *method* call.
  # @option opt [String] :separator     Default: #DEFAULT_ELEMENT_SEPARATOR
  # @option opt [Symbol] :link_method   Default: :search_link
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
  # @return [nil]                       If access method unsupported by *item*.
  #
  def search_links(item, **opt)

    opt, html_opt = partition_options(opt, *SEARCH_LINKS_OPTIONS)
    method = opt[:method]
    field  = (opt[:field] || :title).to_s
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
    unless item.respond_to?(method)
      __debug { "#{__method__}: #{item.class}: item.#{method} invalid" }
      return
    end
    html_opt[:field] = field

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
        send(link_method, record, **link_opt)
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
  # @param [Model, String] terms
  # @param [Hash]          opt                Passed to #make_link except for:
  #
  # @option opt [Symbol]         :field       Default: :title.
  # @option opt [Boolean]        :all_words
  # @option opt [Boolean]        :no_link
  # @option opt [Symbol, String] :scope
  # @option opt [Symbol, String] :controller
  #
  # @return [ActiveSupport::SafeBuffer]       An HTML link element.
  # @return [nil]                             If no *terms* were provided.
  #
  def search_link(terms, **opt)
    terms = terms.to_s.strip.presence or return
    opt, html_opt = partition_options(opt, *SEARCH_LINK_OPTIONS)
    field = opt[:field] || :title

    # Generate the link label.
    ftype = field_category(field)
    lang  = (ftype == :language)
    label = lang && ISO_639.find(terms)&.english_name || terms
    terms = terms.sub(/\s+\([^)]+\)$/, '') if CREATOR_FIELDS.include?(ftype)

    # If this instance should not be rendered as a link, return now.
    return html_span(label, html_opt) if opt[:no_link]

    # Otherwise, wrap the terms phrase in quotes unless directed to handled
    # each word of the phrase separately.
    ctrl   = opt[:scope] || opt[:controller] || request_parameters[:controller]
    phrase = !opt[:all_words]
    terms  = quote(terms) if phrase

    # Create a tooltip unless one was provided.
    unless (html_opt[:title] ||= opt[:tooltip])
      scope = ctrl && "emma.#{ctrl}.index.tooltip"
      words = phrase ? [terms] : terms.split(/\s/).compact
      words.map! { |word| ISO_639.find(word)&.english_name || word } if lang
      words.map! { |word| quote(word) }
      final = words.pop
      tip_terms =
        if words.present?
          words = words.join(', ')
          field.to_s.pluralize   << ' ' << "containing #{words} or #{final}" # TODO: I18n
        else
          field.to_s.singularize << ' ' << final
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
    make_link(label, path, **html_opt)
  end

  # Create record links to an external target or via the internal API interface
  # endpoint.
  #
  # @param [Model, Array<String>, String] links
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
        make_link(link, path, **html_opt)
      else
        html_div(link, class: 'non-link')
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
  # @param [Model, Api::Record, nil] item
  # @param [Hash, nil]               pairs
  #
  # @return [Hash{Symbol=>String}]
  #
  # @yield [item] To supply additional field/value pairs based on *item*.
  # @yieldparam  [Model] item         The supplied *item* parameter.
  # @yieldreturn [Hash]               Result will be merged into *pairs*.
  #
  #--
  # noinspection RubyNilAnalysis, RubyYardReturnMatch
  #++
  def field_values(item, pairs = nil)
    if block_given?
      yield(item).reverse_merge(pairs || {})
    elsif pairs.present?
      pairs
    elsif item.is_a?(ApplicationRecord)
      pairs = item.attributes
      pairs.transform_keys! { |k| k.to_s.titleize.delete(' ').to_sym }
      pairs.transform_values! { |v| v.nil? ? EMPTY_VALUE : v }
      # Convert :file_data and :emma_data into hashes and move to the end.
      if item.is_a?(Upload)
        data = pairs.extract!(:FileData, :EmmaData, :EMMAData)
        pairs[:FileData] = json_parse(data[:FileData])
        pairs[:EmmaData] = json_parse(data[:EmmaData] || data[:EMMAData])
      end
      pairs
    elsif item.is_a?(Api::Record)
      item.field_names.map { |f| [f.to_s.titleize.to_sym, f] }.to_h
    else
      {}
    end
  end

  # Render field/value pairs.
  #
  # @param [Model]               item
  # @param [String, Symbol, nil] model
  # @param [Hash, nil]           pairs        Except for #render_pair options.
  # @param [Integer, nil]        row_offset   Def: 0.
  # @param [String, nil]         separator    Def: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Proc]                block        Passed to #field_values.
  #
  # @option pairs [Integer] :index            Offset to make unique element IDs
  #                                             passed to #render_pair.
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
    if item.is_a?(ApplicationRecord)
      opt, pairs = partition_options(pairs, :index, :row) # Discard :row
      pairs      = field_values(item, pairs, &block)
    elsif item.present?
      pairs      = field_values(item, pairs, &block)
      opt, pairs = partition_options(pairs, :index, :row) # Discard :row
    else
      return ''.html_safe
    end
    cfg = nil
    opt[:row] = row_offset || 0
    # noinspection RubyNilAnalysis
    # @type [Symbol]                 label
    # @type [Symbol, String, Number] value
    pairs.map { |label, value|
      field =
        if value.is_a?(Symbol)
          value
        elsif model
          # noinspection RubyYardParamTypeMatch
          cfg ||= Model.configuration(model)
          if cfg.present?
            cfg.dig(params[:action], :fields, label) ||
              cfg.dig(:fields, :database, label) ||
              cfg.dig(:fields, :form, label) ||
              cfg.dig(:fields, label)
          end
        end
      opt[:row] += 1
      opt[:field] = field
      value = render_value(item, value, model: model)
      render_pair(label, value, **opt) if value
    }.compact.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair.
  #
  # @param [String, Symbol, nil] label
  # @param [Object, nil]         value
  # @param [Symbol, nil]         field
  # @param [Integer, nil]        index      Offset to make unique element IDs.
  # @param [Integer, nil]        row        Display row.
  # @param [String, nil]         separator  Inserted between elements if
  #                                           *value* is an array.
  #
  # @return [ActiveSupport::SafeBuffer]     HTML label and value elements.
  # @return [nil]                           If *value* is blank.
  #
  # == Usage Notes
  # If *label* is HTML then no ".field-???" class is included for the ".label"
  # and ".value" elements.
  #
  #--
  # noinspection RubyNilAnalysis, RubyYardParamTypeMatch
  #++
  def render_pair(label, value, field: nil, index: nil, row: nil, separator: nil)
    return if value.blank?
    prop = Field.configuration(field)
    rng  = html_id(label || 'None')
    type = "field-#{rng}"
    v_id = type.dup
    l_id = +"label-#{rng}"
    [v_id, l_id].each { |id| id << "-#{index}" } if index

    # Extract range values.
    value = value.content if value.is_a?(Field::Type)

    # Mark invalid values.
    # noinspection RubyCaseWithoutElseBlockInspection
    case field
      when :dc_language   then value = mark_invalid_languages(value)
      when :dc_identifier then value = mark_invalid_identifiers(value)
    end

    # Pre-process value(s).
    if prop[:array]
      idx   = 0
      value = Array.wrap(value)
      value = value.map { |v| html_div(v, class: "item-#{idx += 1}") }
      value = safe_join(value, separator)
    elsif value.is_a?(Array)
      separator ||= "<br/>\n".html_safe
      value = safe_join(value, separator)
    end

    # Create a help icon control if applicable.
    help =
      if field == :emma_retrievalLink
        url  = extract_url(value)
        repo = url_repository(url, default: !application_deployed?)
        help_popup(:download, repo)
      end

    # Option settings for both label and value.
    status = []
    if prop[:array]
      status << 'array'
    elsif prop[:type] == 'textarea'
      status << 'textbox'
    end
    row ||= 0
    opt   = { class: css_classes("row-#{row}", type, *status) }

    # Label and label HTML options.
    l_opt = prepend_css_classes(opt, 'label').merge!(id: l_id)
    label = prop[:label] || label || labelize(field)
    if help.present?
      already_html = label.is_a?(ActiveSupport::SafeBuffer)
      label = html_span(label, class: 'text') unless already_html
      label += help
    end
    label = html_div(label, l_opt)

    # Value and value HTML options.
    v_opt = prepend_css_classes(opt, 'value').merge!(id: v_id)
    v_opt[:'aria-labelledby'] = l_id
    value = html_div(value, v_opt)

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
    # noinspection RubyYardReturnMatch
    render_pair(nil, message)
  end

  # Transform a field value for HTML rendering.
  #
  # @param [Model]               item
  # @param [Object, nil]         value
  # @param [String, Symbol, nil] model  If provided, a model-specific method
  #                                       will be invoked instead.
  #
  # @return [Object]  HTML or scalar value.
  # @return [nil]     If *value* was nil or *item* resolved to nil.
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

  VALID_LANGUAGE   = 'Provided value: %s' # TODO: I18n
  INVALID_LANGUAGE = 'The underlying data contains this value ' \
                     'instead of a valid ISO 639 language code.'

  # Wrap invalid language values in a <span>.
  #
  # @param [*, Array<*>] value
  #
  # @return [*, Array<*>]
  #
  def mark_invalid_languages(value)
    return value.map { |v| send(__method__, v) } if value.is_a?(Array)
    name = IsoLanguage.find(value)&.english_name
    if value == name
      value
    elsif name.present?
      tip = VALID_LANGUAGE % value.inspect
      html_span(name, title: tip)
    else
      tip = INVALID_LANGUAGE % value.inspect
      html_span(value, title: tip, class: 'invalid')
    end
  end

  # Wrap invalid identifier values in a <span>.
  #
  # @param [*, Array<*>] value
  #
  # @return [*, Array<*>]
  #
  def mark_invalid_identifiers(value)
    return value.map { |v| send(__method__, v) } if value.is_a?(Array)
    type, id = value.split(':', 2)
    return value if id.nil? || valid_identifier?(type.to_s, id)
    tip = "This is not a valid #{type.upcase} identifier." # TODO: I18n
    ERB::Util.h("#{type}:") << html_span(id, class: 'invalid', title: tip)
  end

  # Indicate whether the given identifier is valid.
  #
  # @param [String] type
  # @param [String] value
  #
  def valid_identifier?(type, value)
    case type
      when 'isbn' then isbn?(value)
      when 'issn' then issn?(value)
      when 'oclc' then oclc?(value)
      when 'lccn' then lccn?(value)
      else             value.present?
    end
  end

  # Attempt to interpret *method* as an *item* method or as a method defined
  # in the current context.
  #
  # @param [Model]             item
  # @param [String, Symbol, *] m
  # @param [Hash]              opt    Options (used only if appropriate).
  #
  # @return [Object]                  HTML or scalar value.
  # @return [nil]                     If executed method returned nil.
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

  # Method options which are processed internally and not passed on as HTML
  # options.
  #
  # @type [Array<Symbol>]
  #
  ITEM_ENTRY_OPT = %i[index offset level row skip].freeze

  # Generate applied search terms and top/bottom pagination controls.
  #
  # @param [Hash, nil] _terms         Passed to `#applied_search_terms`.
  # @param [Integer]   count          Default: `#total_items`.
  # @param [Integer]   row
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def index_controls(_terms, count: nil, row: 1)
    page_controls = pagination_controls
    result = []
    result << nil # With Select2, applied search term display is redundant.
    result <<
      html_div(class: "pagination-top row-#{row + 1}") do
        page_controls + pagination_count(count || total_items)
      end
    result <<
      html_div(class: 'pagination-bottom') do
        page_controls
      end
  end

  # Render an element containing the ordinal position of an entry within a list
  # based on the provided *offset* and *index*.
  #
  # @param [Model]     item
  # @param [Hash, nil] opt            Passed to #html_tag except for:
  #
  # @option opt [Integer] :index      Required index number.
  # @option opt [Integer] :offset     Default: `#page_offset`.
  # @option opt [Integer] :level      Heading tag level (@see #html_tag).
  # @option opt [Object]  :skip       Ignored.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [index,offset] To supply additional parts within .number element.
  # @yieldparam  [Integer] index      The effective index number.
  # @yieldparam  [Integer] offset     The effective page offset.
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>]
  #
  def list_entry_number(item, opt = nil)
    opt, html_opt = partition_options(opt, *ITEM_ENTRY_OPT)
    return unless item && opt[:index]
    index  = non_negative(opt[:index])
    row    = positive(opt[:row])
    offset = opt[:offset]&.to_i || page_offset
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
    prepend_css_classes!(html_opt, 'container')
    container = html_tag(opt[:level], html_opt) { parts }

    # Wrap the container in the actual number grid element.
    outer_opt = { class: 'number' }
    append_css_classes!(outer_opt, "row-#{row}") if row
    html_div(container, outer_opt)
  end

  # Render a single entry for use within a list of items.
  #
  # @param [Model]          item
  # @param [String, Symbol] model
  # @param [Hash, nil]      pairs         Label/value pairs.
  # @param [Proc]           block         Passed to #render_field_values.
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
    html_div(html_opt) do
      if item
        render_field_values(item, model: model, pairs: pairs, &block)
      else
        render_empty_value
      end
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render an item metadata listing.
  #
  # @param [Model]          item
  # @param [String, Symbol] model
  # @param [Hash, nil]      pairs         Label/value pairs.
  # @param [Proc]           block         Passed to #render_field_values.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If *item* is blank.
  #
  def item_details(item, model, pairs = nil, &block)
    return if item.blank?
    html_div(class: "#{model}-details") do
      render_field_values(item, model: model, pairs: pairs, &block)
    end
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Indicate whether the given field value produces an <input> that should be
  # disabled.
  #
  # @param [Symbol, String]      field
  # @param [Symbol, String, nil] model
  #
  # @see UploadHelper#upload_readonly_form_field?
  #
  def readonly_form_field?(field, model)
    model_method = "#{model}_#{__method__}"
    model.present? && respond_to?(model_method) && send(model_method, field)
  end

  # Indicate whether the given field value is required for validation.
  #
  # @param [Symbol, String]      field
  # @param [Symbol, String, nil] model
  #
  # @see UploadHelper#upload_required_form_field?
  #
  def required_form_field?(field, model)
    model_method = "#{model}_#{__method__}"
    model.present? && respond_to?(model_method) && send(model_method, field)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Render pre-populated form fields.
  #
  # @param [Model]               item
  # @param [String, Symbol, nil] model
  # @param [Hash, nil]           pairs  Label/value pairs.
  # @param [Proc]                block  Passed to #render_form_fields.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_fields(item, model, pairs = nil, &block)
    render_form_fields(item, model: model, pairs: pairs, &block)
  end

  # Render field/value pairs.
  #
  # @param [Model]               item
  # @param [String, Symbol, nil] model
  # @param [Hash, nil]           pairs        Except #render_form_pair options.
  # @param [Integer, nil]        row_offset   Def: 0.
  # @param [String, nil]         separator    Def: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Proc]                block        Passed to #field_values.
  #
  # @option pairs [Integer] :index            Offset to make unique element IDs
  #                                             passed to #render_form_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # Compare with:
  # @see #render_field_values
  #
  def render_form_fields(
    item,
    model:      nil,
    pairs:      nil,
    row_offset: nil,
    separator:  DEFAULT_ELEMENT_SEPARATOR,
    &block
  )
    if item.is_a?(ApplicationRecord)
      opt, pairs = partition_options(pairs, :index, :row) # Discard :row
      pairs      = field_values(item, pairs, &block)
    elsif item.present?
      pairs      = field_values(item, pairs, &block)
      opt, pairs = partition_options(pairs, :index, :row) # Discard :row
    else
      return ''.html_safe
    end
    cfg = nil
    opt[:row] = row_offset || 0
    # noinspection RubyNilAnalysis
    # @type [Symbol]                 label
    # @type [Symbol, String, Number] value
    pairs.map { |label, value|
      # @type [Symbol, String] field
      field =
        if value.is_a?(Symbol)
          value
        elsif model
          # noinspection RubyYardParamTypeMatch
          cfg ||= Model.configuration(model)
          if cfg.present?
            cfg.dig(params[:action], :fields, label) ||
              cfg.dig(:fields, :database, label) ||
              cfg.dig(:fields, :form, label) ||
              cfg.dig(:fields, label)
          end
        end
      opt[:row] += 1
      opt[:field]    = field
      opt[:disabled] = readonly_form_field?(field, model) if field
      opt[:required] = required_form_field?(field, model) if field
      value = render_value(item, value, model: model)
      render_form_pair(label, value, **opt)
    }.compact.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair.
  #
  # @param [String, Symbol] label
  # @param [Object, nil]    value
  # @param [Symbol]         field       For 'data-field' attribute.
  # @param [Integer]        index       Offset for making unique element IDs.
  # @param [Integer]        row         Display row.
  # @param [Boolean]        disabled
  # @param [Boolean]        required    For 'data-required' attribute.
  #
  # @return [ActiveSupport::SafeBuffer] HTML label and value elements.
  # @return [nil]                       If *value* is blank.
  #
  # Compare with:
  # @see #render_pair
  #
  #--
  # noinspection RubyNilAnalysis, RubyYardParamTypeMatch
  #++
  def render_form_pair(
    label,
    value,
    field:    nil,
    index:    nil,
    row:      1,
    disabled: nil,
    required: nil
  )
    # Pre-process label to derive names and identifiers.
    base = html_id(label || 'None')
    type = "field-#{base}"
    name = field&.to_s || base
    prop = Field.configuration(field)
    return if prop[:ignored]

    # Pre-process value.
    render_method = placeholder = range = nil
    if value == EMPTY_VALUE
      placeholder = value
      value = nil
    elsif value.is_a?(Field::Type)
      range = value.base if valid_range?(value.base)
      multi = (value.mode == :multiple)
      value = value.value
      render_method =
        if range
          multi ? :render_form_menu_multi  : :render_form_menu_single
        else
          multi ? :render_form_input_multi : :render_form_input
        end
    end
    render_method ||= :render_form_input
    placeholder   ||= prop[:placeholder]
    value    = Array.wrap(value).reject(&:blank?)
    disabled = prop[:readonly] if disabled.nil?
    required = prop[:required] if required.nil?

    # Create a help icon control if applicable.  (The associated popup panel
    # require some special handling to get it to appear above other elements
    # that are in different stacking contexts.)
    help =
      if field == :emma_repository
        help_popup(:upload, :repository, panel: { class: 'z-order-capture' })
      end

    # Create status marker icon.
    status = []
    status << :required if required
    status << :disabled if disabled
    status << :invalid  if required && value.empty?
    status << :valid    if value.present?
    marker = status_marker(status: status, label: label)

    # Option settings for both label and value.
    opt = { class: css_classes("row-#{row}", type, *status) }

    # Label for input element.
    l_opt = append_css_classes(opt, 'label')
    l_opt[:id]      = "label-#{base}"
    l_opt[:for]     = name
    l_opt[:title] ||= prop[:tooltip] if prop[:tooltip]
    label = prop[:label] || label
    label = label ? ERB::Util.h(label) : labelize(name)
    if help.present?
      label = html_span(label, class: 'text')
      label = html_span { label << help }
    end
    label = label_tag(name, l_opt) { label << marker }

    # Input element pre-populated with value.
    v_opt = append_css_classes(opt, 'value')
    v_opt[:id]                = index ? "#{type}-#{index}" : type
    v_opt[:name]              = name
    v_opt[:title]             = 'System-generated; not modifiable.' if disabled # TODO: I18n
    v_opt[:readonly]          = true        if disabled # Not :disabled.
    v_opt[:placeholder]       = placeholder if placeholder
    v_opt[:'data-field']      = field       if field
    v_opt[:'data-required']   = true        if required
    v_opt[:'aria-labelledby'] = l_opt[:id]
    v_opt[:base]              = base
    v_opt[:range]             = range       if range
    value = send(render_method, name, value, **v_opt)

    # noinspection RubyYardReturnMatch
    label << value
  end

  # Single-select menu - drop-down.
  #
  # @param [String] name
  # @param [Array]  value             Selected value(s) from `range#values`.
  # @param [Class]  range             A class derived from EnumType whose
  #                                     #values method will be used to populate
  #                                     the menu.
  # @param [Hash]   opt               Passed to #select_tag except for:
  #
  # @option opt [String] :name        Overrides *name*
  # @option opt [String] :base        Name and id for <select>; default: *name*
  #
  # @raise [StandardError]            If *range* is not an EnumType.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see updateMenu() in javascripts/feature/file-upload.js
  #
  def render_form_menu_single(name, value, range:, **opt)
    valid_range?(range, exception: true)
    normalize_attributes!(opt)
    opt, html_opt = partition_options(opt, :readonly, :base, :name)
    append_css_classes!(html_opt, 'menu', 'single')
    field = html_opt[:'data-field']
    name  = opt[:name] || name || opt[:base] || field

    selected = Array.wrap(value).compact.presence || ['']

    menu =
      range.pairs.map do |item_value, item_label|
        item_value = item_value.to_s
        item_label ||= item_value.titleize
        [item_label, item_value]
      end
    menu.unshift(['(unset)', '']) # TODO: I18n
    menu = options_for_select(menu, selected)
    html_opt[:disabled] = true if opt[:readonly]
    select_tag(name, menu, html_opt)
  end

  # Multi-select menu - scrollable list of checkboxes.
  #
  # @param [String] name
  # @param [Array]  value             Selected value(s) from `range#values`.
  # @param [Class]  range             A class derived from EnumType whose
  #                                     #values method will be used to populate
  #                                     the menu.
  # @param [Hash]   opt               Passed to #field_set_tag except for:
  #
  # @option opt [String] :name        Overrides *name*
  # @option opt [String] :base        Name and id for <select>; default: *name*
  #
  # @raise [StandardError]            If *range* is not an EnumType.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see updateFieldsetCheckboxes() in javascripts/feature/file-upload.js
  #
  def render_form_menu_multi(name, value, range:, **opt)
    valid_range?(range, exception: true)
    normalize_attributes!(opt)
    opt, html_opt = partition_options(opt, :id, :readonly, :base, :name)
    append_css_classes!(html_opt, 'menu', 'multi')
    field = html_opt[:'data-field']
    name  = opt[:name] || name || opt[:base] || field

    selected = Array.wrap(value).compact.presence

    field_opt = html_opt.merge(role: 'listbox', name: name, multiple: true)
    field_opt[:disabled] = true if opt[:readonly]
    # noinspection RubyYardReturnMatch
    field_set_tag(nil, field_opt) do
      div_opt = html_opt.except(:'data-field', :'data-required')
      div_opt[:id]       = opt[:id]
      div_opt[:tabindex] = -1
      html_div(div_opt) do
        cb_opt = { role: 'option' }
        range.pairs.map do |item_value, item_label|
          cb_name          = "[#{field}][]"
          cb_value         = item_value
          cb_opt[:id]      = "#{field}_#{item_value}"
          cb_opt[:checked] = selected&.include?(item_value)
          cb_opt[:label]   = item_label
          render_check_box(cb_name, cb_value, **cb_opt)
        end
      end
    end
  end

  # Multiple single-line inputs.
  #
  # @param [String] name
  # @param [Array]  value
  # @param [Hash]   opt               Passed to :field_set_tag except for:
  #
  # @option [Boolean] :disabled       Passed to :render_form_input
  # @option [Integer] :count
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see updateFieldsetInputs() in javascripts/feature/file-upload.js
  #
  def render_form_input_multi(name, value, **opt)
    opt = append_css_classes(opt, 'input', 'multi')
    render_field_item(name, value, **opt)
  end

  # render_form_input
  #
  # @param [String] name
  # @param [*]      value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see updateTextInputField() in javascripts/feature/file-upload.js
  #
  def render_form_input(name, value, **opt)
    opt = append_css_classes(opt, 'input', 'single')
    render_field_item(name, value, **opt)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # Mapping of actual type to the appropriate field type indicator.
  #
  # @type [Hash{Class=>Symbol}]
  #
  RENDER_FIELD_TYPE = {
    Boolean                     => :check,
    FalseClass                  => :check,
    TrueClass                   => :check,
    Integer                     => :number,
    IsoYear                     => :year,
    ActiveModel::Type::Date     => :date,
    ActiveModel::Type::DateTime => :date,
    Date                        => :date,
    DateTime                    => :date,
    IsoDate                     => :date,
    ActiveModel::Type::Time     => :time,
    ActiveSupport::TimeWithZone => :time,
    Time                        => :time,
  }.freeze

  # Convert certain field types.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  REPLACE_FIELD_TYPE = {
    year: :text, # Currently treating :year as plain text.
    date: :text, # Currently treating :date as plain text.
    time: :text, # Currently treating :time as plain text.
  }.freeze

  # render_field_item
  #
  # @param [String] name
  # @param [*]      value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_field_item(name, value, **opt)
    normalize_attributes!(opt)
    opt, html_opt = partition_options(opt, :base, :name)
    field = html_opt[:'data-field']
    name  = opt[:name] || name || opt[:base] || field
    value = Array.wrap(value).reject(&:blank?)
    type  = Field.configuration(field)[:type]
    type  = type.to_sym if type.is_a?(String)
    type  = RENDER_FIELD_TYPE[value.first.class] unless type.is_a?(Symbol)
    type  = REPLACE_FIELD_TYPE[type] || type || :text
    value =
      case type
        when :check    then true?(value.first)
        when :number   then value.first.to_s.remove(/[^\d]/)
        when :year     then value.first.to_s.sub(/\s.*$/, '')
        when :date     then value.first.to_s
        when :time     then value.first.to_s.sub(/^([^ ]+).*$/, '\1')
        when :textarea then value.join("\n").split(/[ \t]*\n[ \t]*/).join("\n")
        else value.map { |v| v.to_s.strip.presence }.compact.join(' | ')
      end
    # noinspection RubyYardReturnMatch
    case type
      when :check    then render_check_box(name, value, **html_opt)
      when :number   then number_field_tag(name, value, html_opt.merge(min: 0))
      when :year     then text_field_tag(name, value, html_opt)
      when :date     then date_field_tag(name, value, html_opt)
      when :time     then time_field_tag(name, value, html_opt)
      when :textarea then text_area_tag(name, value, html_opt)
      else                text_field_tag(name, value, html_opt)
    end
  end

  # Local options for #render_check_box.
  #
  # @type [Array<Symbol>]
  #
  CHECK_OPTIONS =
    %i[id checked disabled readonly required data-required label].freeze

  # render_check_box
  #
  # @param [String] name
  # @param [*]      value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_check_box(name, value, **opt)
    opt, html_opt = partition_options(opt, *CHECK_OPTIONS)
    normalize_attributes!(opt)

    # Checkbox control.
    checked  = opt.delete(:checked)
    checkbox = check_box_tag(name, value, checked, opt)

    # Label for checkbox.
    lbl_opt  = { for: opt[:id] }.compact
    label    = opt.delete(:label) || value
    label    = label_tag(name, label, lbl_opt)

    # Checkbox/label combination.
    append_css_classes!(html_opt, 'checkbox', 'single')
    html_div(html_opt) { checkbox << label }
  end

  # STATUS_MARKER
  #
  # @type [Hash{Symbol=>Hash{Symbol=>String}}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  STATUS_MARKER = I18n.t('emma.upload.status_marker', default: {}).deep_freeze

  # Generate a marker which can indicate the status of an input field.
  #
  # @param [Symbol, Array<Symbol>] status   One or more of %[invalid required].
  # @param [String, Symbol]        label    Used with :required.
  # @param [Hash]                  opt      Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def status_marker(status: nil, label: nil, **opt)
    opt = prepend_css_classes(opt, 'status-marker')
    status = Array.wrap(status).compact
    append_css_classes!(opt, *status) if status.present?
    icon, tip =
      %i[required disabled invalid valid].find { |state|
        next unless status.include?(state) && (entry = STATUS_MARKER[state])
        break entry.values
      } || STATUS_MARKER.values.last.values
    if icon
      opt[:'data-icon'] = icon
    end
    if tip
      if tip.include?('%')
        label &&= label.to_s.sub(/[[:punct:]]+$/, '')
        tip %= { This: (label ? %Q("#{label}") : 'This') } # TODO: I18n
      end
      opt[:'data-title'] = tip
      opt[:title] ||= tip
    end
    html_span(icon, opt)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # Indicate whether the value is a valid range type.
  #
  # @param [*]       range
  # @param [Boolean] exception        If *true*, raise an exception if *false*.
  #
  def valid_range?(range, exception: false)
    valid = range.is_a?(Class) && (range < EnumType)
    exception &&= !valid
    raise "range: #{range.inspect}: not a subclass of EnumType" if exception
    valid
  end

  # Translate attributes.
  #
  # @param [Hash] opt
  #
  # @return [Hash]                    The potentially-modified *opt* hash.
  #
  def normalize_attributes!(opt)

    field = opt.delete(:field)
    opt[:'data-field'] = field if field

    required = opt.delete(:required) || opt[:'data-required']
    opt[:'data-required'] = true         if required
    append_css_classes!(opt, 'required') if required

    # Disabled input fields are given the :readonly attribute because the
    # :disabled attribute prevents those fields from being included in the data
    # sent with the form submission.
    disabled = opt.delete(:disabled)
    readonly = opt[:readonly] || disabled
    opt[:readonly] = true                if readonly
    append_css_classes!(opt, 'disabled') if readonly

    opt

  end

end

__loading_end(__FILE__)
