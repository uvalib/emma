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
  include BookshareHelper
  include ApiHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Separator for a list formed by HTML elements.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  DEFAULT_ELEMENT_SEPARATOR = "\n".html_safe.freeze

  # Separator for a list formed by text phrases.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  DEFAULT_LIST_SEPARATOR = "<br/>\n".html_safe.freeze

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
    Api::Common::TitleMethods::CREATOR_TYPES.map(&:to_sym).freeze

  # Options which are consumed locally by the named methods and are not passed
  # on to the underlying method.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  RESOURCE_LINK_OPTIONS = {
    item_link:    %i[label no_link path path_method tooltip scope controller],
    search_links: %i[field method method_opt separator link_method],
    search_link:  %i[field all_words no_link scope controller],
    record_links: %i[no_link separator],
  }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Api::Record::Base]   item
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
  # @yield [path]
  # @yieldparam  [String] terms
  # @yieldreturn [String] path
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def item_link(item, label = nil, path = nil, **opt)
    html_opt, opt = extract_options(opt, RESOURCE_LINK_OPTIONS[__method__])
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
        scope ||= (params[:controller] if defined?(params))
        scope &&= "emma.#{scope}.show.tooltip"
        html_opt[:title] = I18n.t(scope, default: '')
      end
      make_link(label, path, html_opt)
    end
  end

  # Item terms as search links.
  #
  # Items in returned in two separately sorted groups: actionable links (<a>
  # elements) followed by items which are not linkable (<span> elements).
  #
  # @param [Api::Record::Base] item
  # @param [Symbol, nil]       field  Default: :title
  # @param [Hash]              opt    Passed to :link_method except for:
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

    html_opt, opt = extract_options(opt, RESOURCE_LINK_OPTIONS[__method__])
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

  # Create a link to the search results index page for the given term(s).
  #
  # @param [Api::Record::Base, String] terms
  # @param [Symbol, nil]               field  Default: :title
  # @param [Hash]                      opt    Passed to #make_link except for:
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
    html_opt, opt = extract_options(opt, RESOURCE_LINK_OPTIONS[__method__])
    field = opt[:field] || field || :title
    terms = terms.to_s.strip
    return if terms.blank?

    # Generate the link label.
    ftype = field_category(field)
    label = (ftype == :language) && ISO_639.find(terms)&.english_name || terms
    terms = terms.sub(/\s+\([^)]+\)$/, '') if CREATOR_FIELDS.include?(ftype)

    # If this instance should not be rendered as a link, return now.
    return content_tag(:span, label, **html_opt) if opt[:no_link]

    # Otherwise, wrap the terms phrase in quotes unless directed to handled
    # each word of the phrase separately.
    ctrl   = opt[:scope] || opt[:controller]
    ctrl ||= (params[:controller] if defined?(params))
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

    make_link(label, path, html_opt)
  end

  # Create record links to an external target or via the internal API interface
  # endpoint.
  #
  # @param [Api::Record::Base, Array<String>, String] links
  # @param [Hash] opt                 Passed to #make_link except for:
  #
  # @option opt [Boolean] :no_link
  # @option opt [String]  :separator  Default: #DEFAULT_ELEMENT_SEPARATOR.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def record_links(links, **opt)
    html_opt, opt = extract_options(opt, RESOURCE_LINK_OPTIONS[__method__])
    prepend_css_classes!(html_opt, 'external-link')
    separator = opt[:separator] || DEFAULT_ELEMENT_SEPARATOR
    no_link   = opt[:no_link]
    links = links.record_links if links.is_a?(Api::Record::Base)
    Array.wrap(links).map { |link|
      next if link.blank?
      path = (external_url(link) unless no_link)
      if path.present? && !path.match?(/[{}]/)
        make_link(link, path, html_opt)
      else
        content_tag(:div, link, class: 'non-link')
      end
    }.compact.join(separator).html_safe
  end

  # A direct link to a Bookshare page to open in a new browser tab.
  #
  # @overload bookshare_link(item)
  #   @param [Api::Record::Base] item
  #
  # @overload bookshare_link(item, path, **path_opt)
  #   @param [String] item
  #   @param [String] path
  #   @param [Hash]   path_opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bookshare_link(item, path = nil, **path_opt)
    html_opt = { target: '_blank' }
    if item.is_a?(Api::Record::Base)
      label = item.identifier
      path  = bookshare_url("browse/book/#{label}", **path_opt)
      tip   = 'View this item on the Bookshare website.' # TODO: I18n
    else
      label = item.to_s
      path  = bookshare_url(path, **path_opt)
      tip   = 'View on the Bookshare website.' # TODO: I18n
    end
    make_link(label, path, target: '_blank', title: tip)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Field/value pairs.
  #
  # If *label_value_pairs* is not provided (as a parameter or through a block)
  # then `item#fields` is used.
  #
  # @param [Api::Record::Base] item
  # @param [Hash, nil]         pairs
  #
  # @option pairs [String] :separator   Default: #DEFAULT_ELEMENT_SEPARATOR.
  #
  # @yield [item]
  # @yieldparam  [Api::Record::Base] item
  # @yieldreturn [Hash]                   The value for *label_value_pairs*.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def field_values(item, pairs = nil)
    pairs ||= yield(item) if block_given?
    pairs ||= item.fields.map { |f| [f, f] }.to_h
    separator = pairs[:separator] || DEFAULT_ELEMENT_SEPARATOR
    pairs.map { |k, v|
      next if k == :separator
      # noinspection RubyCaseWithoutElseBlockInspection
      case v
        when FalseClass
          v = v.to_s
        when Symbol
          v =
            case field_category(v)
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
              when :numImage    then item.image_count
              when :numPage     then item.page_count
              when :thumbnail   then thumbnail(item)
              else                   item.send(v) if item.respond_to?(v)
            end
      end
      field_value(k, v)
    }.compact.join(separator).html_safe
  end

  # Field/value pair.
  #
  # @param [String, Symbol] label
  # @param [Object]         value
  # @param [String, nil]    separator   Def.: #DEFAULT_LIST_SEPARATOR
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                               If *value* is blank.
  #
  # == Usage Notes
  # If *label* is HTML then no ".field-???" class is included for the ".label"
  # and ".value" elements.
  #
  def field_value(label, value, separator: DEFAULT_LIST_SEPARATOR)
    return if value.blank? || false?(value)
    type = nil
    unless label.is_a?(ActiveSupport::SafeBuffer)
      type  = " field-#{label || 'None'}"
      label = labelize(label)
    end
    label = content_tag(:div, label, class: "label#{type}")
    value = safe_join(value, separator) + separator if value.is_a?(Array)
    value = content_tag(:div, value, class: "value#{type}")
    # noinspection RubyYardReturnMatch
    label << value
  end

  # An indicator that can be used to stand for an empty list.
  #
  # @param [String, nil] message      Default: #NO_RESULTS.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def empty_field_value(message = NO_RESULTS)
    field_value(nil, message)
  end

  # The type of named field regardless of pluralization or presence of a
  # "_list" suffix.
  #
  # @param [Symbol, String] name
  #
  # @return [Symbol]
  #
  def field_category(name)
    name.to_s.delete_suffix('_list').singularize.to_sym
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Active search terms.
  #
  # @param [Hash, nil]                 pairs    Default: `#url_parameters`.
  # @param [Symbol, Array<Symbol, nil] only
  # @param [Symbol, Array<Symbol, nil] except
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
      plural = v.is_a?(Enumerable) && (v.size > 1)
      field  = labelize(k)
      field  = (plural ? field.pluralize : field.singularize).html_safe
      value  = v.to_s.sub(/^\s*(["'])(.*)\1\s*$/, '\2').inspect
      [field, value]
    }.to_h
  end

  # A control displaying the currently-applied search terms in the current
  # scope (by default).
  #
  # @param [Hash, nil] term_list      Default: `#search_terms`.
  # @param [Hash]      opt            Passed to the innermost :content_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def applied_search_terms(term_list = nil, **opt)
    opt = prepend_css_classes(opt, 'term')
    leader = 'Search terms:' # TODO: I18n
    leader &&= content_tag(:div, leader, class: 'label')
    separator = content_tag(:span, ';', class: 'term-separator')
    terms =
      (term_list || search_terms).map do |field, value|
        label = content_tag(:span, field, class: 'field')
        sep   = content_tag(:span, ':',   class: 'separator')
        value = content_tag(:span, value, class: 'value')
        content_tag(:div, (label + sep + value), opt)
      end
    content_tag(:div, class: 'applied-search-terms') do
      content_tag(:div, class: 'search-terms') do
        leader + safe_join(terms, separator)
      end
    end
  end

end

__loading_end(__FILE__)
