# app/helpers/model_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the display and creation of Model instances
# (both database items and API messages).
#
module ModelHelper

  include Emma::Common
  include Emma::Json
  include Emma::Unicode

  include Model::Configuration

  include PaginationHelper
  include HelpHelper
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
    Bs::Shared::CreatorMethods::CREATOR_TYPES.map(&:to_sym).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<Symbol>]
  MODEL_LINK_OPTIONS =
    %i[label no_link path path_method tooltip scope controller].freeze

  # Create a link to the details show page for the given model instance.
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
  def model_link(item, **opt)
    opt, html_opt = partition_hash(opt, *MODEL_LINK_OPTIONS)
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
      # noinspection RubyMismatchedParameterType
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

    opt, html_opt = partition_hash(opt, *SEARCH_LINKS_OPTIONS)
    meth  = opt[:method]
    field = (opt[:field] || :title).to_s
    case field
      when 'creator_list'
        meth ||= field.to_sym
        field  = :author
      when /_list$/
        meth ||= field.to_sym
        field  = field.delete_suffix('_list').to_sym
      else
        meth ||= field.pluralize.to_sym
        field  = field.to_sym
    end
    unless item.respond_to?(meth)
      __debug { "#{__method__}: #{item.class}: item.#{meth} invalid" }
      return
    end
    html_opt[:field] = field

    separator   = opt[:separator]   || DEFAULT_ELEMENT_SEPARATOR
    link_method = opt[:link_method] || :search_link
    check_link  = !opt.key?(:no_link)

    method_opt  = (opt[:method_opt].presence if item.method(meth).arity >= 0)
    values      = method_opt ? item.send(meth, **method_opt) : item.send(meth)
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
    opt, html_opt = partition_hash(opt, *SEARCH_LINK_OPTIONS)
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

    # noinspection RubyMismatchedParameterType
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
    css_selector  = '.external-link'
    opt, html_opt = partition_hash(opt, :no_link, :separator)
    prepend_classes!(html_opt, css_selector)
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
  # @param [Model, Api::Record, *] item
  # @param [Hash, nil]             pairs
  #
  # @return [Hash]
  #
  # @yield [item] To supply additional field/value pairs based on *item*.
  # @yieldparam  [Model] item         The supplied *item* parameter.
  # @yieldreturn [Hash]               Result will be merged into *pairs*.
  #
  #--
  # noinspection RubyNilAnalysis, RubyMismatchedReturnType
  #++
  def field_values(item, pairs = nil)
    if block_given?
      yield(item).reverse_merge(pairs || {})
    elsif pairs.present?
      pairs
    elsif item.is_a?(ApplicationRecord)
      # Convert :file_data and :emma_data into hashes and move to the end.
      data, pairs = partition_hash(item.fields, :file_data, :emma_data)
      data.each_pair { |k, v| pairs[k] = json_parse(v) }
    elsif item.is_a?(Api::Record)
      item.field_names.map { |f| [f.to_s.titleize.to_sym, f] }.to_h
    else
      {}
    end
  end

  # Render field/value pairs.
  #
  # @param [Model, nil]          item
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
    pairs  = field_values(item, pairs, &block)
    model  = (model  || model_for(item) || params[:controller])&.to_sym
    action = (action || params[:action])&.to_sym

    opt[:row]   = row_offset || 0
    opt[:model] = model

    value_opt = opt.slice(:model, :index, :min_index, :max_index, :no_format)

    # noinspection RubyNilAnalysis
    pairs.map { |k, v|
      config = field = label = value = nil
      if v.is_a?(Symbol)
        field = v
      elsif k.is_a?(Symbol)
        if v.is_a?(Hash)
          config = v
          value  = k
        end
      elsif model
        config = Field.configuration_for_label(k, model, action)
        field  = config[:field]
      end
      field  ||= k
      config ||= Field.configuration_for_label(field, model, action)
      label  ||= config[:label] || k || labelize(field)
      value  ||= v
      opt[:row]    += 1
      opt[:field]   = field
      opt[:title] ||= config[:tooltip] if config.key?(:tooltip)
      # noinspection RubyMismatchedParameterType
      value = render_value(item, value, **value_opt)
      render_pair(label, value, **opt) if value
    }.compact.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair.
  #
  # @param [String, Symbol, nil] label
  # @param [*]                   value
  # @param [Symbol, nil]         field
  # @param [Symbol, nil]         model      Default: `params[:controller]`
  # @param [Integer, nil]        index      Offset to make unique element IDs.
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
  #--
  # noinspection RubyMismatchedParameterType
  #++
  def render_pair(
    label,
    value,
    field:     nil,
    model:     nil,
    index:     nil,
    row:       1,
    separator: nil,
    **opt
  )
    return if value.blank?
    model ||= params[:controller]
    prop = Field.configuration_for(field, model)
    rng  = html_id((label || 'None'), camelize: true)
    type = "field-#{rng}"
    v_id = type.dup
    l_id = +"label-#{rng}"
    [v_id, l_id].each { |id| id << "-#{index}" } if index

    # Extract range values.
    value = value.content if value.is_a?(Field::Type)

    # Format the content of certain fields.
    unless Array.wrap(opt.delete(:no_format)).include?(field)
      # noinspection RubyCaseWithoutElseBlockInspection
      case field
        when :dc_description
          format_description(value).tap do |parts|
            if parts.size > 1
              value = parts
              prop  = prop.merge(type: 'textarea')
            end
          end
        when :dc_identifier
          value = mark_invalid_identifiers(value)
        when :dc_language
          value = mark_invalid_languages(value)
      end
    end

    # Pre-process value(s).
    if prop[:array]
      v_idx = 0
      value = Array.wrap(value)
      value = value.map { |v| html_div(v, class: "item-#{v_idx += 1}") }
      value = safe_join(value, separator)
    elsif value.is_a?(Array)
      separator ||= HTML_BREAK
      value = safe_join(value, separator)
    end

    # Create a help icon control if applicable.
    if (help = prop[:help]).present?
      replace = topic = nil
      if field == :emma_retrievalLink
        url     = extract_url(value)
        topic   = url_repository(url, default: !application_deployed?)
        replace = help.is_a?(Array) && (help.size > 1)
      end
      help = replace ? (help[0..-2] << topic) : [*help, topic] if topic
      help = help_popup(*help)
    end

    # Option settings for both label and value.
    status   = ('array'     if prop[:array])
    status ||= ('textbox'   if prop[:type] == 'textarea')
    status ||= ('numeric'   if prop[:type] == 'number')
    status ||= ('hierarchy' if prop[:type] == 'json')
    status ||= (prop[:type] if prop[:type].is_a?(String))
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
  def render_empty_value(message = NO_RESULTS)
    # noinspection RubyMismatchedReturnType
    render_pair(nil, message)
  end

  # Transform a field value for HTML rendering.
  #
  # @param [Model]               item
  # @param [*]                   value
  # @param [String, Symbol, nil] model  If provided, a model-specific method
  #                                       will be invoked instead.
  # @param [Hash]                opt    Passed to render method.
  #
  # @return [Any]   HTML or scalar value.
  # @return [nil]   If *value* was *nil* or *item* resolved to *nil*.
  #
  def render_value(item, value, model: nil, **opt)
    if model && respond_to?((model_method = "#{model}_render_value"))
      send(model_method, item, value, **opt)
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

  # Match a major section title in a table-of-contents listing.
  #
  # @type [Regexp]
  #
  #--
  # noinspection SpellCheckingInspection
  #++
  SECTION_TITLE_RE = /^(PART|[CDILMVX]+\.?|[cdilmvx]+\.|\d+\.|v\.) +(.*)/

  # For use with String#scan to step through quote/attribute pairs.
  #
  # @type [Regexp]
  #
  BLURB_RE = /([^\n]*?[[:punct:]]) *-- *([^\n]+?\.\s+|[^\n]+\s*)/

  # Reformat descriptions which are structured in a way that one would find
  # in MARC metadata.
  #
  # @param [String] text
  #
  # @return [Array<String>]
  #
  # == Usage Notes
  # Descriptions like this don't currently seem to appear very often in search
  # results.  Even for those that do, they may not adhere to the expected
  # layout of information, and this method may not be that beneficial in those
  # cases.
  #
  def format_description(text)
    case text
      when /"";/                      # Seen in some IA records.
        text = text.gsub(/"" ""|""""/, '""; ""')

      when /\.--v\. */                # Seen in some IA records.
        text = text.sub(/(\S) +(v[^.\s]*\.) */, '\1 -- \2 ')
        text.gsub!(/(\S) *-- *(v[^.\s]*\.) */, '\1; \2 ')

      when /; *PART */i               # Seen in some IA records.
      when /:;/                       # Observed in one unusual case.
      when /[[:punct:]] *--.* +-- +/  # Blurbs/quotes with attribution.
      when / +-- +.* +-- +/           # Table-of-contents title list.
      when /(;[^;]+){4,}/             # Many sections indicated.

      else                            # Otherwise not treated as "structured".
        return [text]
    end
    q_section = nil
    text.split(/ *; */).flat_map { |part|
      next if (part = part.strip).blank?
      case part
        when /^""(.*)""$/
          # == Rare type of table-of-contents listing entry
          line = $1.to_s
          if line.match(SECTION_TITLE_RE)
            gap       = ("\n" unless q_section)
            q_section = $1.to_s
            [gap, "#{q_section} #{$2}", "\n"].compact
          else
            q_section = nil
            line.match?(/^\d+ +/) ? line : "#{BLACK_CIRCLE}#{EN_SPACE}#{line}"
          end

        when / +-- +.* +-- +/
          # === Table-of-contents listing
          section = nil
          part.split(/ +-- +/).flat_map { |line|
            if line.match(SECTION_TITLE_RE)
              gap     = ("\n" unless section)
              section = $1.to_s.delete_suffix('.')
              [gap, "#{section}. #{$2}", "\n"].compact
            else
              section = nil
              "#{BLACK_CIRCLE}#{EN_SPACE}#{line}"
            end
          }.tap { |toc| toc << "\n" unless toc.last == "\n" }

        when /[[:punct:]] *--/
          # === Blurbs/quotes with attribution
          part.scan(BLURB_RE).flat_map do |paragraph, attribution|
            attribution.remove!(/[.\s]+$/)
            ["#{paragraph} #{EM_DASH}#{attribution}.", "\n"]
          end

        when /^v[^.]*\. *\d/
          # === Apparent table-of-contents volume title
          [part]

        else
          # === Plain text section
          part = "#{part}." unless part.match?(/[[:punct:]]$/)
          [part, "\n"]
      end
    }.compact.map { |line|
      line.gsub(/---/, EM_DASH).gsub(/--/,  EN_DASH)
    }
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Attempt to interpret *method* as an *item* method or as a method defined
  # in the current context.
  #
  # @param [Model]             item
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
    counts << pagination_count(count, total)
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
  # @param [Hash]           opt           Passed to #render_field_values.
  # @param [Proc]           block         Passed to #render_field_values.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def model_list_item(item, model:, pairs: nil, **opt, &block)
    opt[:model]  = model ||= model_for(item)
    css_selector = ".#{model}-list-item"
    html_opt     = { class: css_classes(css_selector) }
    row          = positive(opt[:row])
    append_classes!(html_opt, "row-#{row}") if row
    if item.nil?
      append_classes!(html_opt, 'empty')
    else
      if item.respond_to?(:state_group)
        # noinspection RubyNilAnalysis
        html_opt[:'data-group'] = opt[:group] = item.state_group
      end
      # noinspection RailsParamDefResolve
      id = item.try(:submission_id) || item.try(:identifier) || hex_rand
      html_opt[:id] = "#{model}-#{id}"
    end
    html_opt[:'data-title_id']         = item.try(:emma_titleId)
    html_opt[:'data-normalized_title'] = item.try(:normalized_title)
    html_opt[:'data-sort_date']        = item.try(:emma_sortDate)
    html_opt[:'data-remediation_date'] = item.try(:emma_lastRemediationDate)
    html_opt[:'data-item_score']       = item.try(:total_score, precision: 2)
    html_div(html_opt) do
      if item
        render_field_values(item, pairs: pairs, **opt, &block)
      else
        render_empty_value
      end
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Make the heading row stick to the top of the table when scrolling.
  #
  # @type [Boolean]
  #
  # @see file:app/assets/stylesheets/shared/controls/_table.scss "CSS class .sticky-head"
  #
  STICKY_HEAD = true

  # Give the heading row a background.
  #
  # @type [Boolean]
  #
  # @see file:app/assets/stylesheets/shared/controls/_table.scss "CSS class .dark-head"
  #
  DARK_HEAD = true

  # Options used by some or all of the methods involved in rendering items in
  # a tabular form.
  #
  # @type [Array<Symbol>]
  #
  MODEL_TABLE_OPTIONS = [
    MODEL_TABLE_FIELD_OPT = %i[columns],
    MODEL_TABLE_HEAD_OPT  = %i[sticky dark],
    MODEL_TABLE_ENTRY_OPT = %i[inner_tag outer_tag],
    MODEL_TABLE_ROW_OPT   = %i[row col],
    MODEL_TABLE_TABLE_OPT = %i[model thead tbody tfoot],
  ].flatten.freeze

  # Render model items as a table.
  #
  # @param [Model, Array<Model>] list
  # @param [Hash]                opt    Passed to outer #html_tag except for:
  #
  # @option opt [Symbol, String]            :model
  # @option opt [ActiveSupport::SafeBuffer] :thead  Pre-generated <thead>.
  # @option opt [ActiveSupport::SafeBuffer] :tbody  Pre-generated <tbody>.
  # @option opt [ActiveSupport::SafeBuffer] :tfoot  Pre-generated <tfoot>.
  # @option opt [*] #MODEL_TABLE_OPTIONS            Passed to render methods.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [list, **opt] Allows the caller to define the table contents.
  # @yieldparam  [Hash]         parts   Accumulated :thead/:tbody/:tfoot parts.
  # @yieldparam  [Array<Model>] list    Normalized item list.
  # @yieldparam  [Hash]         opt     Updated options.
  # @yieldreturn [void] Block should update *parts*.
  #
  # @see #STICKY_HEAD
  # @see #DARK_HEAD
  #
  def model_table(list, **opt)
    opt, html_opt = partition_hash(opt, *MODEL_TABLE_OPTIONS)
    opt.reverse_merge!(sticky: STICKY_HEAD, dark: DARK_HEAD)
    list  = Array.wrap(list)
    model = (opt.delete(:model) || model_for(list.first))&.to_s || 'model'
    css_selector = ".#{model}-table"

    parts = %i[thead tbody tfoot].map { |k| [k, opt.delete(k)] }.to_h
    yield(parts, list, **opt) if block_given?
    parts[:thead] ||= model_table_headings(list, **opt)
    parts[:tbody] ||= model_table_entries(list, **opt)
    count = parts[:thead].scan(/<th[>\s]/).size

    prepend_classes!(html_opt, css_selector)
    append_classes!(html_opt, "columns-#{count}") if count.positive?
    append_classes!(html_opt, 'sticky-head')      if opt[:sticky]
    append_classes!(html_opt, 'dark-head')        if opt[:dark]
    html_tag(:table, html_opt) do
      parts.map { |tag, content| html_tag(tag, content) if content }
    end
  end

  # Render one or more entries for use within a <tbody>.
  #
  # @param [Model, Array<Model>] list
  # @param [String, nil]         separator
  # @param [Integer, nil]        row        Current row (prior to first entry).
  # @param [Hash]                opt        Passed to #model_table_entry
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<ActiveSupport::SafeBuffer>]  If :separator is *nil*.
  #
  # @yield [item, **opt] Allows the caller to define the item table entry.
  # @yieldparam  [Model] item         Single item instance.
  # @yieldparam  [Hash]  opt          Row-specific options.
  # @yieldreturn [ActiveSupport::SafeBuffer]
  #
  def model_table_entries(list, separator: "\n", row: 1, **opt)
    rows      = Array.wrap(list).dup
    first_row = row + 1
    last_row  = row + rows.size
    rows.map! do |item|
      row += 1
      row_opt = opt.merge(row: row)
      append_classes!(row_opt, 'row-first') if row == first_row
      append_classes!(row_opt, 'row-last')  if row == last_row
      if block_given?
        yield(item, **row_opt)
      else
        model_table_entry(item, **row_opt)
      end
    end
    rows.compact!
    separator ? safe_join(rows, separator) : rows
  end

  # Render a single entry for use within a table of items.
  #
  # @param [Model]                                     item
  # @param [Integer]                                   row
  # @param [Integer]                                   col
  # @param [Symbol, String]                            outer_tag
  # @param [Symbol, String]                            inner_tag
  # @param [String, Symbol, Array<String,Symbol>, nil] columns
  # @param [Hash]                                      opt
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<ActiveSupport::SafeBuffer>]  If nil :outer_tag.
  # @return [Array<String>]                     If nil :inner_tag, :outer_tag.
  #
  # @yield [item, **opt] Allows the caller to generate the item columns.
  # @yieldparam  [Model] item         Single item instance.
  # @yieldparam  [Hash]  opt          Field generation options.
  # @yieldreturn [Hash{Symbol=>*}]    Same as #model_field_values return type.
  #
  def model_table_entry(
    item,
    row:        1,
    col:        1,
    outer_tag:  :tr,
    inner_tag:  :td,
    columns:    nil,
    filter:     nil,
    **opt
  )
    opt.except!(*MODEL_TABLE_OPTIONS)
    fv_opt = { columns: columns, filter: filter }
    pairs  =
      if block_given?
        yield(item, **fv_opt)
      else
        model_field_values(item, **fv_opt)
      end
    fields =
      if inner_tag
        first_col = col
        last_col  = pairs.size + col - 1
        pairs.map do |field, value|
          row_opt = model_rc_options(field, row, col, opt)
          append_classes!(row_opt, 'col-first') if col == first_col
          append_classes!(row_opt, 'col-last')  if col == last_col
          col += 1
          html_tag(inner_tag, value, row_opt)
        end
      else
        pairs.values.compact.map { |value| ERB::Util.h(value) }
      end
    fields = html_tag(outer_tag, fields) if outer_tag
    fields
  end

  # Render column headings for a table of model items.
  #
  # @param [Model, Array<Model>]                       item
  # @param [Integer]                                   row
  # @param [Integer]                                   col
  # @param [Symbol, String]                            outer_tag
  # @param [Symbol, String]                            inner_tag
  # @param [Boolean]                                   dark
  # @param [Symbol, String, Array<Symbol,String>, nil] columns
  # @param [Hash]                                      opt
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<ActiveSupport::SafeBuffer>]  If nil :outer_tag.
  # @return [Array<String>]                     If nil :inner_tag, :outer_tag.
  #
  # @yield [item, **opt] Allows the caller to generate the item columns.
  # @yieldparam  [Model] item         Single item instance.
  # @yieldparam  [Hash]  opt          Field generation options.
  # @yieldreturn [ActiveSupport::SafeBuffer]
  #
  # @see #DARK_HEAD
  #
  def model_table_headings(
    item,
    row:        1,
    col:        1,
    outer_tag:  :tr,
    inner_tag:  :th,
    dark:       DARK_HEAD,
    columns:    nil,
    filter:     nil,
    **opt
  )
    opt.except!(*MODEL_TABLE_OPTIONS)

    first  = Array.wrap(item).first
    fv_opt = { columns: columns, filter: filter }
    fields =
      if block_given?
        yield(first, **fv_opt)
      else
        model_field_values(first, **fv_opt)
      end
    fields = fields.dup  if fields.is_a?(Array)
    fields = fields.keys if fields.is_a?(Hash)
    fields = Array.wrap(fields).compact

    if inner_tag
      first_col = col
      last_col  = fields.size + col - 1
      fields.map! do |field|
        row_opt = model_rc_options(field, row, col, opt)
        append_classes!(row_opt, 'col-first') if col == first_col
        append_classes!(row_opt, 'col-last')  if col == last_col
        col += 1
        html_tag(inner_tag, row_opt) do
          html_div(labelize(field), class: 'field')
        end
      end
    else
      fields.map! { |field| labelize(field) }
    end

    if outer_tag
      fields = html_tag(outer_tag, fields)
      fields = html_tag(outer_tag, '', class: 'spanner') << fields if dark
    end

    fields
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  protected

  # Specified field selections from the given model instance.
  #
  # @param [Model, Hash, nil]                          item
  # @param [String, Symbol, Array<String,Symbol>, nil] columns
  # @param [String, Symbol, Array<String,Symbol>, nil] default
  # @param [String, Regexp, Array<String,Regexp>, nil] filter
  #
  # @return [Hash{Symbol=>*}]
  #
  def model_field_values(item, columns: nil, default: nil, filter: nil, **)
    # noinspection RailsParamDefResolve
    pairs = item.try(:attributes) || item.try(:stringify_keys)
    return {} if pairs.blank?
    columns = Array.wrap(columns || default).compact_blank.map(&:to_s)
    pairs.slice!(*columns) unless columns.blank? || (columns == %w(all))
    Array.wrap(filter).each do |pattern|
      if pattern.is_a?(Regexp)
        pairs.reject! { |field, _| field.match?(pattern) }
      else
        pairs.reject! { |field, _| field.downcase.include?(pattern) }
      end
    end
    pairs.transform_keys!(&:to_sym)
  end

  # Setup row/column HTML options.
  #
  # @param [Symbol, String] field
  # @param [Integer, nil]   row
  # @param [Integer, nil]   col
  # @param [Hash, nil]      opt
  #
  # @return [Hash]
  #
  def model_rc_options(field, row = nil, col = nil, opt = nil)
    field = html_id(field)
    prepend_classes(opt, field).tap do |html_opt|
      append_classes!(html_opt, "row-#{row}") if row
      append_classes!(html_opt, "col-#{col}") if col
      html_opt[:id] ||= [field, row, col].compact.join('-')
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
  # @option opt [Symbol] :model           Default: `#model_for(item)`.
  # @option opt [String] :class           Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If *item* is blank.
  #
  def model_details(item, pairs: nil, **opt, &block)
    return if item.blank?
    model        = opt[:model] ||= model_for(item)
    css_selector = ".#{model}-details"
    classes      = css_classes(css_selector, opt.delete(:class))
    html_div(class: classes) do
      render_field_values(item, pairs: pairs, **opt, &block)
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
  # @param [Symbol, String, nil] model  Default: `params[:controller]`
  #
  # @see UploadHelper#upload_readonly_form_field?
  #
  def readonly_form_field?(field, model = nil)
    model ||= params[:controller]
    Field.configuration_for(field, model)[:readonly].present?
  end

  # Indicate whether the given field value is required for validation.
  #
  # @param [Symbol, String]      field
  # @param [Symbol, String, nil] model  Default: `params[:controller]`
  #
  # @see UploadHelper#upload_required_form_field?
  #
  def required_form_field?(field, model = nil)
    model ||= params[:controller]
    Field.configuration_for(field, model)[:required].present?
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Render field/value pairs.
  #
  # @param [Model]               item
  # @param [String, Symbol, nil] model        Default: `params[:controller]`.
  # @param [String, Symbol, nil] action       Default: `params[:action]`.
  # @param [Hash, nil]           pairs        Except #render_form_pair options.
  # @param [Integer, nil]        row_offset   Def: 0.
  # @param [String, nil]         separator    Def: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Hash]                opt
  # @param [Proc]                block        Passed to #field_values.
  #
  # @option opt [Integer] :index              Offset to make unique element IDs
  #                                             passed to #render_form_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # Compare with:
  # #render_field_values
  #
  #--
  # noinspection RubyNilAnalysis, RubyMismatchedParameterType
  #++
  def render_form_fields(
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
    pairs  = field_values(item, pairs, &block)
    model  = (model  || params[:controller])&.to_sym
    action = (action || params[:action])&.to_sym

    opt[:row]   = row_offset || 0
    opt[:model] = model

    pairs.map { |label, value|
      field = lbl = val = nil
      if value.is_a?(Symbol)
        field = value
      elsif (label == :file_data) || (label == :emma_data)
        next
      elsif label.is_a?(Symbol) && value.is_a?(Hash)
        field = label
        lbl   = value[:label]
        val   = field
      elsif label.is_a?(Symbol)
        field = label
        lbl   = Field.configuration_for(field, model, action)[:label]
      elsif model
        field = Field.configuration_for_label(label, model, action)[:field]
      end
      # @type [String] label
      label       = lbl || label || labelize(field)
      value       = val || value
      opt[:field] = field
      opt[:row]  += 1
      opt[:disabled] = readonly_form_field?(field, model) if field
      opt[:required] = required_form_field?(field, model) if field
      value = render_value(item, value, model: model, index: opt[:index])
      render_form_pair(label, value, **opt)
    }.compact.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair.
  #
  # @param [String, Symbol] label
  # @param [*]              value
  # @param [Symbol]         field       For 'data-field' attribute.
  # @param [Symbol, String] model       Default: `params[:controller]`
  # @param [Integer]        index       Offset for making unique element IDs.
  # @param [Integer]        row         Display row.
  # @param [Boolean]        disabled
  # @param [Boolean]        required    For 'data-required' attribute.
  # @param [Hash]                opt
  #
  # @return [ActiveSupport::SafeBuffer] HTML label and value elements.
  # @return [nil]                       If *value* is blank.
  #
  # Compare with:
  # #render_pair
  #
  def render_form_pair(
    label,
    value,
    field:    nil,
    model:    nil,
    index:    nil,
    row:      1,
    disabled: nil,
    required: nil,
    **opt
  )
    # Pre-process label to derive names and identifiers.
    base = html_id((label || 'None'), camelize: true)
    type = "field-#{base}"
    name = field&.to_s || base
    model ||= params[:controller]
    prop = Field.configuration_for(field, model)
    return if prop[:ignored]
    return if prop[:role] && !has_role?(prop[:role])

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
    value    = Array.wrap(value).compact_blank
    disabled = prop[:readonly] if disabled.nil?
    required = prop[:required] if required.nil?

    # Create a help icon control if applicable.  (The associated popup panel
    # require some special handling to get it to appear above other elements
    # that are in different stacking contexts.)
    help = prop[:help].presence
    help &&= help_popup(*help, panel: { class: 'z-order-capture' })

    # Create status marker icon.
    status = []
    status << :required if required
    status << :disabled if disabled
    status << :invalid  if required && value.empty?
    status << :valid    if value.present?
    marker = status_marker(status: status, label: label)

    # Option settings for both label and value.
    prepend_classes!(opt, "row-#{row}", type, *status)
    l_id = "label-#{base}"
    v_id = index ? "#{type}-#{index}" : type
    fieldset = false # (render_method == :render_form_menu_multi)

    # Label for input element.
    l_opt = append_classes(opt, 'label')
    l_opt[:id]      = l_id
    l_opt[:for]     = v_id
    l_opt[:title] ||= prop[:tooltip] if prop[:tooltip]
    label  = prop[:label] || label
    wrap   = !label.is_a?(ActiveSupport::SafeBuffer)
    label  = label ? ERB::Util.h(label) : labelize(name)
    legend = (label.dup if fieldset)
    label  = html_span(label, class: 'text') if wrap
    label  = html_span { label << help }     if help
    label << marker
    label  = fieldset ? html_div(label, l_opt) : label_tag(name, label, l_opt)

    # Input element pre-populated with value.
    v_opt = append_classes(opt, 'value')
    v_opt[:id]                = v_id
    v_opt[:name]              = name
    v_opt[:title]             = 'System-generated; not modifiable.' if disabled # TODO: I18n
    v_opt[:readonly]          = true        if disabled # Not :disabled.
    v_opt[:placeholder]       = placeholder if placeholder
    v_opt[:'data-field']      = field       if field
    v_opt[:'data-required']   = true        if required
    v_opt[:'aria-labelledby'] = l_id
    v_opt[:base]              = base
    v_opt[:range]             = range       if range
    v_opt[:legend]            = legend      if legend
    value = send(render_method, name, value, **v_opt)

    # noinspection RubyMismatchedReturnType
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
  # @raise [RuntimeError]             If *range* is not an EnumType.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/entry-form.js *updateMenu()*
  #
  def render_form_menu_single(name, value, range:, **opt)
    css_selector = '.menu.single'
    valid_range?(range, exception: true)
    normalize_attributes!(opt)
    opt, html_opt = partition_hash(opt, :readonly, :base, :name)
    field = html_opt[:'data-field']
    name  = opt[:name] || name || opt[:base] || field
    prepend_classes!(html_opt, css_selector)

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
  # @raise [RuntimeError]             If *range* is not an EnumType.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/entry-form.js *updateFieldsetCheckboxes()*
  #
  def render_form_menu_multi(name, value, range:, **opt)
    css_selector = '.menu.multi'
    valid_range?(range, exception: true)
    normalize_attributes!(opt)
    opt, html_opt = partition_hash(opt, :id, :readonly, :base, :name)
    field = html_opt[:'data-field']
    name  = opt[:name] || name || opt[:base] || field
    prepend_classes!(html_opt, css_selector)

    # Checkbox elements.
    selected = Array.wrap(value).compact.presence
    cb_opt   = { role: 'option' }
    checkboxes =
      range.pairs.map do |item_value, item_label|
        cb_name          = "[#{field}][]"
        cb_value         = item_value
        cb_opt[:id]      = "#{field}_#{item_value}"
        cb_opt[:label]   = item_label
        cb_opt[:checked] = selected&.include?(item_value)
        render_check_box(cb_name, cb_value, **cb_opt)
      end

    # Grouped checkboxes (Chrome problem with styling <fieldset>).
    gr_opt = html_opt.except(:'data-field', :'data-required')
    gr_opt.merge!(role: 'listbox', multiple: true, name: name)
    gr_opt[:tabindex] = -1
    group = html_div(*checkboxes, gr_opt)

    field_opt = html_opt.merge(id: opt[:id], name: name)
    field_opt[:disabled] = true if opt[:readonly]
    html_div(field_opt) { group }
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
  # @see file:app/assets/javascripts/feature/entry-form.js *updateFieldsetInputs()*
  #
  def render_form_input_multi(name, value, **opt)
    css_selector = '.input.multi'
    render_field_item(name, value, **prepend_classes!(opt, css_selector))
  end

  # render_form_input
  #
  # @param [String] name
  # @param [*]      value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/entry-form.js *updateTextInputField()*
  #
  def render_form_input(name, value, **opt)
    css_selector = '.input.single'
    render_field_item(name, value, **prepend_classes!(opt, css_selector))
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Form submit button.
  #
  # @param [Hash]                config   Button info for model actions.
  # @param [String, Symbol, nil] action   Default: `params[:action]`.
  # @param [String, nil]         label    Override button label.
  # @param [Hash] opt                     Passed to #submit_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_submit_button(config:, action: nil, label: nil, **opt)
    css_selector = '.submit-button'
    action ||= params[:action]
    config   = config.dig(action&.to_sym, :submit) || {}
    label  ||= config[:label]

    prepend_classes!(opt, css_selector)
    opt[:title] ||= config.dig(:disabled, :tooltip)
    # noinspection RubyMismatchedReturnType
    submit_tag(label, opt)
  end

  # Form cancel button.
  #
  # @param [Hash]                config   Button info for model actions.
  # @param [String, Symbol, nil] action   Default: `params[:action]`.
  # @param [String, nil]         label    Override button label.
  # @param [String, Hash, nil]   url      Default: `history.back()`.
  # @param [Hash] opt                     Passed to #button_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_cancel_button(config:, action: nil, label: nil, url: nil, **opt)
    css_selector = '.cancel-button'
    action ||= params[:action]
    config   = config.dig(action&.to_sym, :cancel) || {}
    label  ||= config[:label]

    prepend_classes!(opt, css_selector)
    opt[:title] ||= config[:tooltip]
    opt[:type]  ||= 'reset'

    if opt[:'data-path'].present?
      button_tag(label, opt)
    else
      url ||= (request.referer if local_request? && !same_request?)
      url ||= 'javascript:history.back();'
      # noinspection RubyMismatchedParameterType
      make_link(label, url, **opt)
    end
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  protected

  # Field type indicators mapped on to related class(es).
  #
  # @type [Hash{Symbol=>Array<Class>}]
  #
  RENDER_FIELD_TYPE_TABLE = {
    check:  [Boolean, TrueClass, FalseClass],
    date:   [IsoDate, IsoDay, Date, DateTime],
    number: [Integer, BigDecimal],
    time:   [Time, ActiveSupport::TimeWithZone],
    year:   [IsoYear],
  }.transform_values! { |types|
    types.flat_map { |type|
      [type].tap do |related|
        name = (type == BigDecimal) ? 'Decimal' : type
        related << safe_const_get("Axiom::Types::#{name}")
        related << safe_const_get("ActiveModel::Type::#{name}")
      end
    }.compact
  }.deep_freeze

  # Mapping of actual type to the appropriate field type indicator.
  #
  # @type [Hash{Class=>Symbol}]
  #
  RENDER_FIELD_TYPE =
    RENDER_FIELD_TYPE_TABLE.flat_map { |field, types|
      types.map { |type| [type, field] }
    }.sort_by { |pair| pair.first.to_s }.to_h.freeze

  # Convert certain field types.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  REPLACE_FIELD_TYPE = {
=begin
    year: :text, # Currently treating :year as plain text.
    date: :text, # Currently treating :date as plain text.
    time: :text, # Currently treating :time as plain text.
=end
  }.freeze

  # render_field_item
  #
  # @param [String] name
  # @param [*]      value
  # @param [Hash]   opt               Passed to render method except for:
  #
  # @option opt [String]         :base
  # @option opt [String]         :name
  # @option opt [Symbol, String] :model   Default: `params[:controller]`
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_field_item(name, value, **opt)
    normalize_attributes!(opt)
    opt, html_opt = partition_hash(opt, :base, :name, :model)
    field = html_opt[:'data-field']
    name  = opt[:name] || name || opt[:base] || field
    value = Array.wrap(value).compact_blank
    model = opt[:model] || params[:controller]
    type  = Field.configuration_for(field, model)[:type]
    type  = type.to_sym                          if type.is_a?(String)
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
    # noinspection RubyMismatchedReturnType
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
    css_selector  = '.checkbox.single'
    opt, html_opt = partition_hash(opt, *CHECK_OPTIONS)
    normalize_attributes!(opt)

    # Checkbox control.
    checked  = opt.delete(:checked)
    checkbox = check_box_tag(name, value, checked, opt)

    # Label for checkbox.
    lbl_opt  = { for: opt[:id] }.compact
    label    = opt.delete(:label) || value
    label    = label_tag(name, label, lbl_opt)

    # Checkbox/label combination.
    html_div(prepend_classes!(html_opt, css_selector)) do
      checkbox << label
    end
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
    css_selector  = '.status-marker'
    status    = Array.wrap(status).compact
    icon, tip =
      %i[required disabled invalid valid].find { |state|
        next unless status.include?(state) && (entry = STATUS_MARKER[state])
        break entry.values
      } || STATUS_MARKER.values.last.values
    if tip
      if tip.include?('%')
        label &&= label.to_s.sub(/[[:punct:]]+$/, '')
        tip %= { This: (label ? %Q("#{label}") : 'This') } # TODO: I18n
      end
      opt[:'data-title'] = tip
      opt[:title] ||= tip
    else
      opt[:'aria-hidden'] = true
    end
    opt[:'data-icon'] = icon if icon
    html_span(icon, prepend_classes!(opt, css_selector, *status))
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
  # @raise [RuntimeError]             If not valid and *exception* is *true*.
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
  # == Implementation Notes
  # Disabled input fields are given the :readonly attribute because the
  # :disabled attribute prevents those fields from being included in the data
  # sent with the form submission.
  #
  def normalize_attributes!(opt)
    field    = opt.delete(:field)    || opt[:'data-field']
    required = opt.delete(:required) || opt[:'data-required']
    readonly = opt.delete(:disabled) || opt[:readonly]

    opt[:'data-field']    = field    if field
    opt[:'data-required'] = true     if required
    opt[:readonly]        = true     if readonly

    append_classes!(opt, 'required') if required
    append_classes!(opt, 'disabled') if readonly
    opt
  end

  # ===========================================================================
  # :section: Item forms (delete pages)
  # ===========================================================================

  public

  # Submit button for the delete model form.
  #
  # @param [Hash]                config   Button info for model actions.
  # @param [String, Symbol, nil] action   Default: `params[:action]`.
  # @param [String, nil]         label    Override button label.
  # @param [String, Hash, nil]   url
  # @param [Hash]                opt      Passed to #button_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def delete_submit_button(config:, action: nil, label: nil, url: nil, **opt)
    css_selector = '.submit-button'
    action ||= params[:action] || :delete
    config   = config.dig(action&.to_sym, :submit) || {}
    label  ||= config[:label]
    opt[:title]  ||= config.dig(:disabled, :tooltip)
    opt[:role]   ||= 'button'
    opt[:method] ||= :delete
    prepend_classes!(opt, css_selector)
    append_classes!(opt, (url ? 'best-choice' : 'forbidden'))
    button_to(label, url, opt)
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
