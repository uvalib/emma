# app/helpers/bookshare_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting access and linkages to the Bookshare API.
#
module BookshareHelper

  include ModelHelper
  include BsApiHelper
  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  BOOKSHARE_SITE    = 'https://www.bookshare.org'
  BOOKSHARE_CMS     = "#{BOOKSHARE_SITE}/cms".freeze
  BOOKSHARE_CATALOG = 'https://catalog.bookshare.org'
  BOOKSHARE_USER    = '%s@bookshare.org'

  # Bookshare actions.
  #
  # Any action not explicitly listed (or listed without a :url value) is
  # implicitly assumed to be a #BOOKSHARE_SITE endpoint.
  #
  # @type [Hash{Symbol=>Hash,String}]
  #
  #--
  # noinspection LongLine
  #++
  BOOKSHARE_ACTION = {
    bookActionHistory:  "#{BOOKSHARE_CATALOG}/bookActionHistory",
    submitBook:         "#{BOOKSHARE_CATALOG}/submitBook",
    bookEditMetadata:   "#{BOOKSHARE_CATALOG}/bookEditMetadata",
    bookWithdrawal:     "#{BOOKSHARE_CATALOG}/bookWithdrawal",
    orgAccountMembers: {
      Add:    "#{BOOKSHARE_SITE}/orgAccountMembers/edit",                                     # TODO: ???
      Edit:   "#{BOOKSHARE_SITE}/orgAccountMembers/edit",
      Remove: "#{BOOKSHARE_SITE}/orgAccountMembers/remove?userIds=%{ids}",                    # TODO: HTTP POST
    },
    orgAccountSponsors: {
      Add:    "#{BOOKSHARE_SITE}/orgAccountSponsors/edit",                                    # TODO: ???
      Edit:   "#{BOOKSHARE_SITE}/orgAccountSponsors/edit",                                    # TODO: controller/model
      Remove: "#{BOOKSHARE_SITE}/orgAccountSponsors/remove?userIds=%{ids}",                   # TODO: controller/model, HTTP POST
    },
    myReadingLists: {
      Add:    "#{BOOKSHARE_SITE}/myReadingLists?readingListId=%{id}&addTitle=%{bookshareId}", # TODO: HTTP POST
      Create: "#{BOOKSHARE_SITE}/myReadingLists/create",
      Edit:   "#{BOOKSHARE_SITE}/myReadingLists/%{id}/edit",
      Delete: "#{BOOKSHARE_SITE}/myReadingLists/%{id}?delete",                                # TODO: HTTP DELETE
    },
  }.deep_freeze

  # Mapping of application URL parameters to Bookshare URL parameters.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>Symbol}}]
  #
  PARAM_MAPPING = {
    title: {
      id: :titleInstanceId
    },
    periodical: {
      id: :seriesId
    },
    edition: {
      id: :editionId
    },
    member: {
      id: :userAccountId
    },
    sponsor: {
      # TODO: sponsor?
    },
    reading_list: {
      id: :readingListId
    },
    subscription: { # TODO: subscription controller/model
      id: :subscriptionId
    },
  }.freeze

  # Mapping of an application action (expressed as "controller-action") to the
  # associated Bookshare action (expressed as a #BOOKSHARE_ACTION key).
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  ACTION_MAPPING = {
    title: {
      history: :bookActionHistory,
      new:     :submitBook,         # TODO: Bookshare way to create a catalog title without uploading an artifact?
      create:  :submitBook,         # TODO: ditto
      edit:    :bookEditMetadata,
      update:  :bookEditMetadata,
      delete:  :bookWithdrawal,
      destroy: :bookWithdrawal,
    },
    periodical: {
      # TODO: periodical?
    },
    edition: {
      # TODO: edition?
    },
    member: {
      new:     %i[orgAccountMembers Add],
      create:  %i[orgAccountMembers Add],
      edit:    %i[orgAccountMembers Edit],
      update:  %i[orgAccountMembers Edit],
      delete:  %i[orgAccountMembers Remove],  # TODO: method
      destroy: %i[orgAccountMembers Remove],  # TODO: method
    },
    sponsor: {
      # TODO: sponsor controller/model?
      new:     %i[orgAccountSponsors Add],
      create:  %i[orgAccountSponsors Add],
      edit:    %i[orgAccountSponsors Edit],
      update:  %i[orgAccountSponsors Edit],
      delete:  %i[orgAccountSponsors Remove],
      destroy: %i[orgAccountSponsors Remove],
    },
    reading_list: {
      new:     %i[myReadingLists Create],
      create:  %i[myReadingLists Create],
      edit:    %i[myReadingLists Edit],
      update:  %i[myReadingLists Edit],
      delete:  %i[myReadingLists Delete],
      destroy: %i[myReadingLists Delete],
    },
    subscription: {
      # TODO: subscription?
    },
  }.deep_freeze

  # Generate overrides for route helpers of actions that must be performed on
  # a Bookshare site and not by an application endpoint.
  #
  # @example Edit catalog title metadata
  #
  # - The route helper :edit_title_path will be defined by ActionDispatch to
  #   refer to the route '/title/:id/edit', however there is currently no API
  #   support for this action so it cannot be implemented in the application.
  #
  # - The ACTION_MAPPING[:title][:edit] entry is used here to generate an
  #   overriding :edit_title_path method which replaces the method generated by
  #   ActionDispatch with one that redirects to the Bookshare URL which serves
  #   to "implement" that action.
  #
  ACTION_MAPPING.each do |controller, actions|
    class_exec do
      actions.keys.each do |action|
        define_method(:"#{action}_#{controller}_path") do |**opt|
          path = { controller: controller, action: action }
          bookshare_url(path, **opt)
        end
      end
    end
  end

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

  # Generate a Bookshare URL.  If *path* is not given, infer it from the
  # originating controller and action.
  #
  # @param [Hash, String, nil] path
  # @param [Hash]              path_opt   Passed to #make_path.
  #
  # @return [String]                      A full URL.
  # @return [nil]                         If the URL could not be determined.
  #
  #--
  # == Variations
  #++
  #
  # @overload bookshare_url(url, **path_opt)
  #   @param [String, nil] url        Full or partial URL.
  #   @param [Hash]        path_opt
  #
  # @overload bookshare_url(hash, **path_opt)
  #   @param [Hash]        hash       Controller/action.
  #   @param [Hash]        path_opt
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def bookshare_url(path, **path_opt)

    # If *path* was not given, get a #BOOKSHARE_ACTION reference based on the
    # current or specified controller/action.
    controller ||= params[:controller]
    action     ||= params[:action]
    unless path.is_a?(String)
      controller = path.is_a?(Hash) && path[:controller] || controller
      action     = path.is_a?(Hash) && path[:action]     || action
      path       = ACTION_MAPPING.dig(controller.to_sym, action.to_sym)
    end
    return if path.blank?

    # If *path* was not given as a full URL, attempt to locate an associated
    # path within #BOOKSHARE_ACTION.  If one was not found then *path* is
    # assumed to be one or more parts of a literal URL.
    lookup_path = BOOKSHARE_ACTION.dig(*path)
    path = Array.wrap(lookup_path || path)
    path.unshift(BOOKSHARE_SITE) unless path.first.to_s.start_with?('http')
    path = path.join('/')

    # If the path contains format references (e.g., "%{id}") then they should
    # be satisfied by the options passed in to the method.
    if (ref_keys = named_references(path, SPRINTF_NAMED_REFERENCE)).present?
      ref_opt, path_opt = partition_hash(path_opt, *ref_keys)
      ref_opt.compact_blank!
      ref_opt.transform_values! { |v| v.is_a?(String) ? url_escape(v) : v }
      ref_opt[:ids] ||= ref_opt[:id]
      ref_opt[:ids] = Array.wrap(ref_opt[:ids]).join(',')
      path = format(path, ref_opt) rescue return
    end

    # Before using the (remaining) options as URL parameters, apply parameter
    # name translations.
    param_map = PARAM_MAPPING[controller.to_sym] || {}
    path_opt =
      path_opt.map { |k, v|
        k = param_map[k] if param_map.key?(k)
        v = v.join(',')  if v.is_a?(Array)
        [k, v] unless k.blank? || v.blank?
      }.compact.to_h

    make_path(path, path_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A direct link to a Bookshare page to open in a new browser tab.
  #
  # @param [Bs::Api::Record, String] item
  # @param [String]                  path
  # @param [Hash]                    path_opt   Passed to #bookshare_url.
  #
  # @return [ActiveSupport::SafeBuffer]         HTML link element.
  # @return [nil]                               If no *path* was found.
  #
  #--
  # == Variations
  #++
  #
  # @overload bookshare_link(item)
  #   @param [Bs::Api::Record] item
  #
  # @overload bookshare_link(item, path, **path_opt)
  #   @param [String] item            Link label.
  #   @param [String] path            Passed as #bookshare_url *path* parameter
  #   @param [Hash]   path_opt
  #
  def bookshare_link(item, path: nil, **path_opt)
    if item.is_a?(Bs::Api::Record)
      label = item.identifier
      tip   = 'View this item on the Bookshare website.' # TODO: I18n
      path  = "browse/book/#{label}"
    else
      label = item.to_s
      tip   = 'View on the Bookshare website.' # TODO: I18n
    end
    path = bookshare_url(path, **path_opt)
    external_link(label, path, title: tip) if path.present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
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

    values = method_opt ? item.send(meth, **method_opt) : item.send(meth)
    values = values.is_a?(Array) ? values.dup : [values]
    values.map! { |record|
      link_opt = html_opt
      if check_link
        # noinspection RubyCaseWithoutElseBlockInspection
        no_link  =
          case field
            when :categories then !record.bookshare_category
          end
        link_opt = link_opt.merge(no_link: no_link) if no_link
      end
      send(link_method, record, **link_opt)
    }.compact!
    values.sort_by! { |html_element|
      term   = html_element.to_s
      prefix = term.start_with?('<a') ? '' : 'ZZZ'
      term.sub(/^<[^>]+>/, prefix)
    }.uniq!
    values.join(separator).html_safe
  end

  # @private
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
      path = (bs_api_explorer_url(link) unless no_link)
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

  # Transform a field value for HTML rendering.
  #
  # @param [Bs::Api::Record] item
  # @param [*]               value
  # @param [Hash]            opt      Passed to the render method.
  #
  # @return [Any]   HTML or scalar value.
  # @return [nil]   If *value* was *nil* or *item* resolved to *nil*.
  #
  # @see ModelHelper::List#render_value
  #
  def bookshare_render_value(item, value, **opt)
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
      else                   render_value(item, value, **opt)
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

  public

  # Transform name(s) into Bookshare username(s).
  #
  # @param [String, Symbol, Array<String,Symbol>] name
  #
  # @return [String]
  # @return [Array<String>]
  #
  #--
  # == Variations
  #++
  #
  # @overload bookshare_user(name)
  #   @param [String, Symbol] name
  #   @return [String]
  #
  # @overload bookshare_user(names)
  #   @param [Array<String,Symbol>] names
  #   @return [Array<String>]
  #
  def bookshare_user(name)
    return name.map { |v| send(__method__, v) } if name.is_a?(Array)
    name = name.to_s.downcase
    # noinspection RubyMismatchedReturnType
    (name.present? && !name.include?('@')) ? (BOOKSHARE_USER % name) : name
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
