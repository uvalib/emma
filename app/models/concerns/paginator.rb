# app/models/concerns/paginator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Encapsulation of pagination parameters.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
class Paginator

  include ActionController::UrlFor
  include Rails.application.routes.url_helpers

  delegate :env, :request, to: :controller

  include Emma::Common
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # NOTE: from SearchTermsHelper::PAGINATION_KEYS
  PAGINATION_KEYS = %i[start offset page prev_id prev_value].freeze

  # URL parameters involved in pagination.
  #
  # @type [Array<Symbol>]
  #
  PAGE_PARAMS = %i[page start offset limit].freeze

  # URL parameters involved in form submission.
  #
  # @type [Array<Symbol>]
  #
  FORM_PARAMS = %i[selected field-group cancel].freeze

  # POST/PUT/PATCH parameters from the entry form that are not relevant to the
  # create/update of a model instance.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_FORM_PARAMS = (PAGE_PARAMS + FORM_PARAMS).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  attr_reader :controller
  attr_reader :context
  private :controller, :context

  attr_reader :initial_parameters

  # Create a new instance.
  #
  # @param [ApplicationController, nil] controller
  # @param [Hash]                       opt         From `#request_parameters`.
  #
  def initialize(controller = nil, **opt)

    @controller = controller
    @context    = extract_hash!(opt, :controller, :action)
    @context[:controller] ||= @controller&.controller_name&.to_sym

    # Get pagination values.
    limit, page, offset =
      opt.values_at(:limit, :page, :offset).map { |v| v&.to_i }
    limit  ||= page_size
    page   ||= (offset / limit) + 1 if offset
    offset ||= (page - 1) * limit   if page

    # Get first and current page paths; adjust values if currently on the first
    # page of results.
    main_page  = request.path
    path_opt   = { decorate: true, unescape: true }
    mp_opt     = opt.merge(path_opt)
    current    = make_path(main_page, **mp_opt)
    first      = main_page
    on_first   = (current == first)
    unless on_first
      mp_opt   = opt.except(*PAGINATION_KEYS).merge!(path_opt)
      first    = make_path(main_page, **mp_opt)
      on_first = (current == first)
    end
    unless on_first
      mp_opt   = opt.except(:limit, *PAGINATION_KEYS).merge!(path_opt)
      first    = make_path(main_page, **mp_opt)
      on_first = (current == first)
    end

    # Unless already on the first page, the previous page link is just
    # 'history.back()'.
    if on_first
      offset = 0
      prev = first = nil
    else
      prev = :back
    end

    # Set current values for the including controller.
    self.page_size   = limit
    self.page_offset = offset
    self.first_page  = first
    self.prev_page   = prev

    # Adjust parameters to be transmitted to the Bookshare API.
    opt[:limit]  = limit
    opt[:offset] = (offset if offset.nonzero?)
    @initial_parameters = url_parameters(opt).compact
  end

  # Finish setting of pagination values based on the result list and original
  # URL parameters.
  #
  # @param [Api::Record, Array] result
  # @param [Symbol, nil]        meth    Method to invoke from *list* for items.
  # @param [Hash]               search  Passed to #next_page_path.
  #
  # @return [Array]                     The value of #page_items.
  #
  def finalize(result, meth = nil, **search)
    self.page_items   = meth && result.try(meth) || result
    self.page_records = record_count(result)
    self.total_items  = item_count(result, default: page_items.size)
    self.next_page    = next_page_path(list: result, **search)
    self.page_items
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Modify the usual result so that the dump of @page_items is replaced with
  # a count of each type of element it contains.
  #
  # @return [String]
  #
  def inspect
    items = page_items.map(&:class)
    items = items.tally.map { |cls, cnt| "#{cnt} #{cls}" }.presence
    items = items&.join(' / ') || 'empty'
    vars  = (instance_variables - %i[@page_items @_url_options]).sort!
    vars  = vars.map { |var| [var, instance_variable_get(var).inspect] }.to_h
    vars  = vars.merge!('@page_items': "(#{items})").map { |k, v| "#{k}=#{v}" }
    "#<#{self.class.name}:#{object_id} %s>" % vars.join(' ')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Pagination data values.
  #
  class Properties < ::Hash

    # Empty copy of data values in the preferred order (for debug output).
    #
    # @type [Hash{Symbol=>any}]
    #
    TEMPLATE = {
      page_size:    nil,
      page_offset:  nil,
      total_items:  nil,
      page_records: nil,
      next_page:    nil,
      prev_page:    nil,
      first_page:   nil,
      last_page:    nil
    }.freeze

    def initialize(values = nil)
      replace(TEMPLATE)
      update(values) if values
    end

  end

  # property
  #
  # @return [Paginator::Properties]
  #
  def property
    @property ||= Properties.new
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the number of results per page.
  #
  # @return [Integer]
  #
  def page_size
    property[:page_size] ||= default_page_size
  end

  # Set the number of results per page.
  #
  # @param [Integer, nil] value
  #
  # @return [Integer]
  #
  def page_size=(value)
    property[:page_size] = value&.to_i || default_page_size
  end

  # Get the path to the first page of results.
  #
  # @return [String]                  URL for the first page of results.
  # @return [nil]                     If @first_page is unset.
  #
  def first_page
    property[:first_page]
  end

  # Set the path to the first page of results.
  #
  # @param [String, Symbol, nil] value
  #
  # @return [String]                  New URL for the first page of results.
  # @return [nil]                     If @first_page is unset.
  #
  def first_page=(value)
    property[:first_page] = page_path(value)
  end

  # Get the path to the last page of results.
  #
  # @return [String]                  URL for the last page of results.
  # @return [nil]                     If @last_page is unset.
  #
  def last_page
    property[:last_page]
  end

  # Set the path to the last page of results.
  #
  # @param [String, Symbol, nil] value
  #
  # @return [String]                  New URL for the last page of results.
  # @return [nil]                     If @last_page is unset.
  #
  def last_page=(value)
    property[:last_page] = page_path(value)
  end

  # Get the path to the next page of results
  #
  # @return [String]                  URL for the next page of results.
  # @return [nil]                     If @next_page is unset.
  #
  def next_page
    property[:next_page]
  end

  # Set the path to the next page of results
  #
  # @param [String, Symbol, nil] value
  #
  # @return [String]                  New URL for the next page of results.
  # @return [nil]                     If @next_page is unset.
  #
  def next_page=(value)
    property[:next_page] = page_path(value)
  end

  # Get the path to the previous page of results.
  #
  # @return [String]                  URL for the previous page of results.
  # @return [nil]                     If @prev_page is unset.
  #
  def prev_page
    property[:prev_page]
  end

  # Set the path to the previous page of results.
  #
  # @param [String, Symbol, nil] value
  #
  # @return [String]                  New URL for the previous page of results.
  # @return [nil]                     If @prev_page is unset.
  #
  def prev_page=(value)
    property[:prev_page] = page_path(value)
  end

  # Get the offset of the current page into the total set of results.
  #
  # @return [Integer]
  #
  def page_offset
    property[:page_offset] ||= 0
  end

  # Set the offset of the current page into the total set of results.
  #
  # @param [Integer, nil] value
  #
  # @return [Integer]
  #
  def page_offset=(value)
    property[:page_offset] = value.to_i
  end

  # Get the total results count.
  #
  # @return [Integer]
  #
  def total_items
    property[:total_items] ||= 0
  end

  # Set the total results count.
  #
  # @param [Integer, nil] value
  #
  # @return [Integer]
  #
  def total_items=(value)
    property[:total_items] = value.to_i
  end

  # Get the number of records returned from the API for this page.
  #
  # @return [Integer]
  #
  def page_records
    property[:page_records] ||= 0
  end

  # Set the number of records returned from the API for this page.
  #
  # @param [Integer, nil] value
  #
  # @return [Integer]
  #
  def page_records=(value)
    property[:page_records] = value.to_i
  end

  # Get the current page of result items.
  #
  # @return [Array]
  #
  def page_items
    @page_items ||= []
  end

  # Set the current page of result items.
  #
  # @param [Array] values
  #
  # @return [Array]
  #
  def page_items=(values)
    @page_items = Array.wrap(values)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Interpret *value* as a URL path or a JavaScript action.
  #
  # @param [String, Symbol, nil] value  One of [:back, :forward, :go].
  # @param [Integer, nil]   page        To #page_history for *action* :go.
  #
  # @return [String]                    A value usable with 'href'.
  # @return [nil]                       If *value* is invalid.
  #
  def page_path(value, page = nil)
    # noinspection RubyMismatchedArgumentType
    value.is_a?(Symbol) ? page_history(value, page) : value.to_s.presence
  end

  # A value to use in place of a path in order to engage browser history.
  #
  # @param [String, Symbol] action    One of [:back, :forward, :go].
  # @param [Integer, nil]   page      History page if *directive* is :go.
  #
  # @return [String]
  #
  def page_history(action, page = nil)
    "javascript:history.#{action}(#{page});"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Analyze the *list* object to generate the path for the next page of
  # results.
  #
  # @param [Api::Record, Array] list
  # @param [Hash]               url_params  For `list.next`.
  #
  # @return [String]                  Path to generate next page of results.
  # @return [nil]                     If there is no next page.
  #
  def next_page_path(list: nil, **url_params)
    list ||= page_items
    # noinspection RailsParamDefResolve
    if list.try(:next).present?

      # General pagination parameters.
      prm    = url_parameters(url_params).except!(:start)
      page   = positive(prm.delete(:page))
      offset = positive(prm.delete(:offset))
      limit  = positive(prm.delete(:limit))
      size   = limit || page_size
      if offset && page
        offset = nil if offset == ((page - 1) * size)
      elsif offset
        page   = (offset / size) + 1
        offset = nil
      else
        page ||= 1
      end
      prm[:page]   = page   + 1    if page
      prm[:offset] = offset + size if offset
      prm[:limit]  = limit         if limit && (limit != default_page_size)

      # Parameters specific to the Bookshare API.
      prm[:start] = list.next

      make_path(request.path, **prm)

    else
      list.try(:get_link, :next)
    end
  end

  # Default results per page for the current controller/action.
  #
  # @return [Integer]
  #
  def default_page_size
    @default_page_size ||= get_page_size
  end

  # Default results per page.
  #
  # @return [Integer]
  #
  def get_page_size
    self.class.get_page_size(@context)
  end

  # Extract the number of "items" reported by an object.
  #
  # @param [Api::Record, Model, Array, Hash, Any, nil] value
  # @param [Hash]                                      opt
  #
  # @return [Integer]
  #
  def item_count(value = nil, **opt)
    value ||= page_items
    self.class.item_count(value, **opt)
  end

  # Determine the number of records reported by an object.
  #
  # @param [Api::Record, Model, Array, Hash, Any, nil] value
  #
  # @return [Integer]
  #
  def record_count(value = nil)
    value ||= page_items
    self.class.record_count(value)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default results per page for the given controller/action.
  #
  # @param [Symbol, String, Hash, nil] c   Controller
  # @param [Symbol, String, nil]       a   Action
  #
  # @return [Integer]
  #
  def self.get_page_size(c = nil, a = nil)
    # noinspection RubyNilAnalysis
    c, a = c.values_at(:controller, :action) if c.is_a?(Hash)
    keys = []
    keys << :"emma.#{c}.#{a}.pagination.page_size" if c && a
    keys << :"emma.#{c}.#{a}.page_size"            if c && a
    keys << :"emma.#{c}.pagination.page_size"      if c
    keys << :"emma.#{c}.page_size"                 if c
    keys << :'emma.generic.pagination.page_size'
    keys << :'emma.generic.page_size'
    keys << :'emma.pagination.page_size'
    keys << :'emma.page_size'
    I18n.t(keys.shift, default: keys).to_i
  end

  # Extract the number of "items" reported by an object.
  #
  # (For aggregate items, this is the number of aggregates as opposed to the
  # number of records from which they are composed.)
  #
  # @param [Api::Record, Model, Array, Hash, Any, nil] value
  # @param [Any]                                       default
  #
  # @return [Integer]
  #
  #--
  # noinspection RubyNilAnalysis, RailsParamDefResolve
  #++
  def self.item_count(value, default: 1)
    result   = (value.size if value.is_a?(Hash) || value.is_a?(Array))
    result ||= value.try(:item_count)   || value.try(:titles).try(:size)
    result ||= value.try(:totalResults) || value.try(:records).try(:size)
    result || default
  end

  # Determine the number of records reported by an object.
  #
  # @param [Api::Record, Model, Array, Hash, Any, nil] value
  #
  # @return [Integer]
  #
  def self.record_count(value)
    Array.wrap(value).sum do |v|
      (v.totalResults  if v.respond_to?(:totalResults))           ||
      (v.records&.size if v.respond_to?(:records))                ||
      (v.size          if v.respond_to?(:size) && !v.is_a?(Hash)) ||
      1
    end
  end

end

__loading_end(__FILE__)
