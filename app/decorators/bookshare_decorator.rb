# app/decorators/bookshare_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base item presenter for Bookshare-related models.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Bs::Api::Record]
#
class BookshareDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for Bs::Api::Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Paths
    include BaseDecorator::Paths
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module Methods

    include BaseDecorator::Methods

    # =========================================================================
    # :section:
    # =========================================================================

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
    # @type [Hash{Symbol=>Hash}]
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

    # =========================================================================
    # :section:
    # =========================================================================

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
    #   @param [String] item      Link label.
    #   @param [String] path      Passed as #bookshare_url *path* parameter
    #   @param [Hash]   path_opt
    #
    # @see LinkHelper#external_link
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

    # Generate a Bookshare URL.  If *path* is not given, infer it from the
    # originating controller and action.
    #
    # @param [Hash, String, nil] path
    # @param [Hash]              prm    Passed to #make_path.
    #
    # @return [String]                  A full URL.
    # @return [nil]                     If the URL could not be determined.
    #
    #--
    # == Variations
    #++
    #
    # @overload bookshare_url(url, **path_opt)
    #   @param [String, nil] url        Full or partial URL.
    #   @param [Hash]        prm
    #
    # @overload bookshare_url(hash, **path_opt)
    #   @param [Hash]        hash       Controller/action.
    #   @param [Hash]        prm
    #
    #--
    # noinspection RubyNilAnalysis
    #++
    def bookshare_url(path, **prm)

      # If *path* was not given, get a #BOOKSHARE_ACTION reference based on the
      # current or specified controller/action.
      controller = model_type
      if path.is_a?(Hash)
        controller = path[:controller]&.to_sym || controller
        action     = path[:action]&.to_sym
        path       = ACTION_MAPPING.dig(controller, action)
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
        ref_opt = extract_hash!(prm, *ref_keys).compact_blank!
        ref_opt.transform_values! { |v| v.is_a?(String) ? url_escape(v) : v }
        ref_opt[:ids] ||= ref_opt[:id]
        ref_opt[:ids] = Array.wrap(ref_opt[:ids]).join(',')
        path = format(path, ref_opt) rescue return
      end

      # Before using the (remaining) options as URL parameters, apply parameter
      # name translations.
      param_map = PARAM_MAPPING[controller] || {}
      path_prm =
        prm.map { |k, v|
          k = param_map[k] if param_map.key?(k)
          v = v.join(',')  if v.is_a?(Array)
          [k, v] unless k.blank? || v.blank?
        }.compact.to_h

      make_path(path, **path_prm)
    end

    # This is a kludge
    #
    # @param [Model] item
    # @param [Hash]  opt            Passed to ArtifactDecorator#download_links
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def artifact_links(item, **opt)
      ctx = opt.delete(:context)&.except(:controller, :action) || {}
      ArtifactDecorator.new(item, context: ctx).download_links(**opt)
    end

  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module InstanceMethods

    include BaseDecorator::InstanceMethods, Paths, Methods

    # =========================================================================
    # :section: BookshareDecorator::Methods overrides
    # =========================================================================

    public

    # The current action is implied.
    #
    # @param [Hash, String, nil] path
    # @param [Hash]              prm
    #
    # @return [String, nil]
    #
    def bookshare_url(path, **prm)
      if path.is_a?(Hash) && !path[:action] && context[:action]
        # noinspection RubyNilAnalysis
        path = path.merge(action: context[:action])
      end
      super(path, **prm)
    end

    # This is a kludge
    #
    # @param [Model, nil] item
    # @param [Hash]       opt       Passed to ArtifactDecorator#download_links
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def artifact_links(item = nil, **opt)
      super((item || object), **opt, context: context)
    end

  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
  module ClassMethods
    include BaseDecorator::ClassMethods, Paths, Methods
  end

  # Cause definitions to be included here and in the associated collection
  # decorator via BaseCollectionDecorator#collection_of.
  #
  module Common
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end
  end

  include Common

  # ===========================================================================
  # :section: BookshareDecorator::Methods overrides
  # ===========================================================================

  public

  # A direct link to a Bookshare page to open in a new browser tab.
  #
  # @param [Hash] path_opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def bookshare_link(**path_opt)
    super(object, **path_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Creator field categories.
  #
  # @type [Array<Symbol>]
  #
  CREATOR_FIELDS =
    Bs::Shared::CreatorMethods::CREATOR_TYPES.map(&:to_sym).freeze

  # @private
  # @type [Array<Symbol>]
  SEARCH_LINK_OPTIONS = %i[field all_words no_link].freeze

  # Create a link to the search results index page for the given term(s).
  #
  # @param [Model, String] terms
  # @param [Hash]          opt                To LinkHelper#make_link except:
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
    html_opt = remainder_hash!(opt, *SEARCH_LINK_OPTIONS)
    terms = terms.to_s.strip.presence or return
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
    ctrlr  = model_type
    phrase = !opt[:all_words]
    terms  = quote(terms) if phrase

    # Create a tooltip unless one was provided.
    unless (html_opt[:title] ||= opt[:tooltip])
      scope = "emma.#{ctrlr}.index.tooltip"
      words = phrase ? [terms] : terms.split(/\s/).compact
      words.map! { |word| ISO_639.find(word)&.english_name || word } if lang
      words.map! { |word| quote(word) }
      final = words.pop
      tip_terms =
        if words.present?
          words = words.join(', ')
          "#{field.to_s.pluralize} containing #{words} or #{final}" # TODO: I18n
        else
          "#{field.to_s.singularize} #{final}"
        end
      html_opt[:title] = I18n.t(scope, terms: tip_terms, default: '')
    end

    # Generate the search path.
    search = Array.wrap(field).map { |f| [f, terms] }.to_h
    search.merge!(controller: ctrlr, action: :index)
    path = path_for(**search)

    # noinspection RubyMismatchedArgumentType
    make_link(label, path, **html_opt)
  end

  # @private
  # @type [Array<Symbol>]
  SEARCH_LINKS_OPTIONS = %i[field method method_opt separator].freeze

  # Catalog item search links.
  #
  # Items in returned in two separately sorted groups: actionable links ('<a>'
  # elements) followed by items which are not linkable ('<span>' elements).
  #
  # @param [Hash] opt                   Passed to :link_method except for:
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
  def search_links(**opt)
    html_opt = remainder_hash!(opt, *SEARCH_LINKS_OPTIONS)
    meth     = opt[:method]
    field    = (opt[:field] || :title).to_s
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
    unless object.respond_to?(meth)
      __debug { "#{__method__}: #{object.class}: object.#{meth} invalid" }
      return
    end
    html_opt[:field] = field

    separator  = opt[:separator] || DEFAULT_ELEMENT_SEPARATOR
    check_link = !opt.key?(:no_link)
    values = execute(object, meth, opt[:method_opt])
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
      # noinspection RubyMismatchedReturnType
      search_link(record, **link_opt)
    }.compact!
    values.sort_by! { |html_element|
      term   = html_element.to_s
      prefix = term.start_with?('<a') ? '' : 'ZZZ'
      term.sub(/^<[^>]+>/, prefix)
    }.uniq!
    values.join(separator).html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Item categories as search links.
  #
  # @param [Hash] opt                 Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def category_links(**opt)
    opt[:field] = :categories
    opt[:all_words] = true
    search_links(**opt)
  end

  # Item formats as search links.
  #
  # @param [Hash] opt                 Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def format_links(**opt)
    opt[:field]     = :fmt
    opt[:all_words] = true
    search_links(**opt)
  end

  # Item languages as search links.
  #
  # @param [Hash] opt                 Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def language_links(**opt)
    opt[:field]     = :language
    opt[:all_words] = true
    search_links(**opt)
  end

  # Item countries as search links.
  #
  # NOTE: This is apparently not working in Bookshare.
  # Although an invalid country code will result in no results, all valid
  # country codes result in the same results.
  #
  # @param [Hash] opt                 Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def country_links(**opt)
    opt[:field]     = :country
    opt[:all_words] = true
    opt[:no_link]   = true
    search_links(**opt)
  end

  # Item author(s) as search links.
  #
  # @param [Hash] opt                 Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def author_links(**opt)
    opt[:field] = :author_list
    search_links(**opt)
  end

  # Item editor(s) as search links.
  #
  # @param [Hash] opt                 Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def editor_links(**opt)
    opt[:field]      = :editor_list
    opt[:method_opt] = { role: true }
    search_links(**opt)
  end

  # Item composer(s) as search links.
  #
  # @param [Hash] opt                 Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def composer_links(**opt)
    opt[:field]      = :composer_list
    opt[:method_opt] = { role: true }
    search_links(**opt)
  end

  # Item narrator(s) as search links.
  #
  # @param [Hash] opt                 Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def narrator_links(**opt)
    opt[:field]      = :narrator_list
    opt[:method_opt] = { role: true }
    search_links(**opt)
  end

  # Item creator(s) as search links.
  #
  # @param [Hash] opt                 Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def creator_links(**opt)
    opt[:field]      = :creator_list
    opt[:method_opt] = { role: true }
    search_links(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create record links to an external target or via the internal API interface
  # endpoint.
  #
  # @param [Model, Array<String>, String] links
  # @param [Boolean]                      no_link
  # @param [String]                       separator
  # @param [Hash]                         opt         To LinkHelper#make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see BsApiHelper#bs_api_explorer_url
  #
  def record_links(
    links,
    no_link:   false,
    separator: DEFAULT_ELEMENT_SEPARATOR,
    **opt
  )
    css = '.external-link'
    prepend_css!(opt, css)
    links = links.record_links if links.respond_to?(:record_links)
    Array.wrap(links).map { |link|
      next if link.blank?
      path = (h.bs_api_explorer_url(link) unless no_link)
      if path.present? && !path.match?(/[{}]/)
        make_link(link, path, **opt)
      else
        html_div(link, class: 'non-link')
      end
    }.compact.join(separator).html_safe
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Any]       value
  # @param [Symbol, *] field
  # @param [Hash]      opt            Passed to the render method or super.
  #
  # @return [Any]                     HTML or scalar value.
  # @return [nil]                     If *value* or *object* is *nil*.
  #
  def render_value(value, field:, **opt)
    if present?
      # noinspection RubyCaseWithoutElseBlockInspection
      case field_category(field || value)
        when :artifact    then artifact_links(**opt)
        when :author      then author_links(**opt)
        when :bookshareId then bookshare_link
        when :category    then category_links(**opt)
        when :composer    then composer_links(**opt)
        when :country     then country_links(**opt)
        when :cover       then cover(**opt)
        when :cover_image then cover(**opt)
        when :creator     then creator_links(**opt)
        when :editor      then editor_links(**opt)
        when :fmt         then format_links(**opt)
        when :format      then format_links(**opt)
        when :language    then language_links(**opt)
        when :link        then record_links(object)
        when :narrator    then narrator_links(**opt)
        when :numImage    then h.number_with_delimiter(object.image_count)
        when :numPage     then h.number_with_delimiter(object.page_count)
        when :thumbnail   then thumbnail(**opt)
        when :title       then link(**opt)
      end
    end || super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

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
  # :section: BaseDecorator::Form overrides
  # ===========================================================================

  public

  # An external link to the appropriate Bookshare endpoint is displayed in
  # place of a local form for creating/modifying objects that reside on
  # Bookshare.
  #
  # Originally this was just a placeholder at a time when it was assumed that
  # the Bookshare API was being created with the intent of supporting the full
  # range of EMMA requirements.  If, at some point, there is a need to have
  # full CRUD access to certain Bookshare-only data objects then this method
  # might be overridden in that particular case.
  #
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [Hash]           opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def model_form(action: nil, **opt)
    opt[:action] = action&.to_sym || DEFAULT_FORM_ACTION
    click_to     = form_action(**opt)
    operate_on   = form_action_description(**opt)
    target       = form_target_description(**opt)
    phrase       = [click_to, operate_on, target]
    html_tag(:p) do
      safe_join(phrase, ' ') << '.'
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # form_action
  #
  # @param [Hash] opt
  #
  # @option opt [Symbol] :action      Default: :new
  #
  # @return [String]
  #
  def form_action(**opt)
    opt[:action] ||= DEFAULT_FORM_ACTION
    if can?(opt[:action])
      here = form_action_link(label: 'here', **opt) # TODO: I18n
      "Click #{here} to".html_safe                  # TODO: I18n
    else
      'User %s cannot' % current_user.to_s.inspect  # TODO: I18n
    end
  end

  # form_action_link
  #
  # @param [String] label
  # @param [Hash]   opt               Passed to #link_to_action.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_action_link(label:, **opt)
    opt[:action] ||= DEFAULT_FORM_ACTION
    # noinspection RubyMismatchedReturnType
    link_to_action(label, **opt)
  end

  # form_action_description
  #
  # @param [Symbol, nil] action
  #
  # @return [String]
  #
  def form_action_description(action: nil, **)
    case action # TODO: I18n
      when :new    then 'create'
      when :edit   then 'modify'
      when :delete then 'remove'
      else              'operate on'
    end
  end

  # form_target_description
  #
  # @return [String]
  #
  def form_target_description(**)
    'Bookshare object' # TODO: I18n
  end

end

__loading_end(__FILE__)
