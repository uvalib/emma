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

  include Emma::Common
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters that are search-related but "out-of-band".
  #
  # @type [Array<Symbol>]
  #
  PAGINATION_KEYS = %i[start offset page prev_id prev_value].freeze

  # URL parameters that are not directly used in searches.
  #
  # @type [Array<Symbol>]
  #
  NON_SEARCH_KEYS = [:api_key, :modal, :limit, *PAGINATION_KEYS].freeze

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

  # Pagination data values.
  #
  # This does not include :page_items so that value can be handled separately
  # for diagnostic reporting.
  #
  class Properties < ::Hash

    # Property names relating to the range of index values on the page.
    #
    # @type [Array<Symbol>]
    #
    INDEX = %i[first_index last_index current_index].freeze

    # Property names relating to cursors for field position per page item.
    #
    # @type [Array<Symbol>]
    #
    POSITION = %i[first_position final_position current_position].freeze

    # Empty copy of data values in the preferred order (for debug output).
    #
    # @type [Hash{Symbol=>any}]
    #
    TEMPLATE = {
      page_number:      nil,
      page_size:        nil,
      page_offset:      nil,

      total_items:      nil,
      page_records:     nil,

      next_page:        nil,
      prev_page:        nil,
      first_page:       nil,
      last_page:        nil,

      first_index:      nil,
      last_index:       nil,
      current_index:    nil,

      first_position:   nil,
      final_position:    nil,
      current_position: nil,
    }.freeze

    def initialize(values = nil)
      replace(TEMPLATE)
      POSITION.each { |k| store(k, {}) }
      update(values) if values
    end

    # All property names.
    #
    # @return [Array<Symbol>]
    #
    def self.keys
      TEMPLATE.keys
    end

  end

  attr_reader :context
  attr_reader :initial_parameters

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [ApplicationController, nil] ctrlr
  # @param [ActionDispatch::Request]    request
  # @param [Hash]                       opt         From `#request_parameters`.
  #
  def initialize(ctrlr = nil, request: nil, **opt)

    @context = extract_hash!(opt, :controller, :action)
    @context[:controller] ||= ctrlr&.controller_name&.to_sym
    @context[:request]    ||= request || ctrlr&.request

    if ctrlr && !ctrlr.is_a?(ApplicationController)
      raise "not an ApplicationController: #{ctrlr.inspect}"
    end
    raise 'no controller given' if @context[:controller].blank?
    raise 'no request given'    if @context[:request].blank?

    # Strip off index cursor initialization values.
    Properties::INDEX.each { |k| property[k] = opt.delete(k)&.to_i }

    # Get pagination values.
    limit, page, offset =
      opt.values_at(:limit, :page, :offset).map { |v| v&.to_i }
    limit  ||= page_size
    page   ||= (offset / limit) + 1 if offset
    offset ||= (page - 1) * limit   if page
    offset   = positive(offset)

    # Get first and current page paths; adjust values if currently on the first
    # page of results.
    main_page  = @context[:request].path
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

    # Sanity check.
    unless application_deployed?
      if on_first
        raise "on_first for opt = #{opt.inspect}" if page.to_i > 1
      else
        raise "no page number for opt = #{opt.inspect}" if page.blank?
      end
    end

    # On the first page, all pagination values retain their defaults.
    # Otherwise the previous page link is just 'history.back()'.
    unless on_first
      self.page_offset = offset
      self.page_number = page
      self.first_page  = first
      self.prev_page   = :back
    end
    self.page_size = limit

    # Set the effective URL parameters, including those required by API calls
    # for paginated results.
    @initial_parameters =
      url_parameters(opt).merge!(offset: offset, limit: limit).compact
  end

  # Finish setting of pagination values based on the result list and original
  # URL parameters.
  #
  # @param [Api::Record, Array, Hash] result
  # @param [Symbol, nil]              meth
  # @param [Hash]                     opt
  #
  # @return [Array]
  #
  #--
  # == Variations
  #++
  #
  # @overload finalize(result, **opt)
  #   Generally for Record-related models.
  #   @param [Hash{Symbol=>*}]    result
  #   @param [Hash]               opt     Passed to #url_for.
  #   @return [Array]                     The value of #page_items.
  #
  # @overload finalize(result, meth = nil, **opt)
  #   Generally for other models (e.g. Bookshare API-related).
  #   @param [Api::Record, Array] result
  #   @param [Symbol, nil]        meth    Method to extract items from result.
  #   @param [Hash]               opt     Passed to #next_page_path.
  #   @return [Array]                     The value of #page_items.
  #
  def finalize(result, meth = nil, **opt)
    # noinspection RubyMismatchedArgumentType
    if result.is_a?(Hash)
      first, last, page = result.values_at(:first, :last, :page)
      self.page_items   = result[:list]
      self.page_size    = result[:limit]
      self.page_offset  = result[:offset]
      self.total_items  = result[:total]
      self.next_page    = (url_for(opt.merge(page: (page + 1))) unless last)
      self.prev_page    = (url_for(opt.merge(page: (page - 1))) unless first)
      self.first_page   = (url_for(opt.except(*PAGE_PARAMS))    unless first)
      self.prev_page    = first_page if page == 2
    else
      self.page_items   = meth && result.try(meth) || result
      self.page_records = record_count(result)
      self.total_items  = item_count(result)
      self.next_page    = next_page_path(list: result, **opt)
    end
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
  # :section: Special definitions
  # ===========================================================================

  public

  # Originating request.
  #
  # @note Defined to support use of external routing methods like #url_for.
  #
  # @return [ActionDispatch::Request]
  #
  def request
    context[:request]
  end

  # Originating environment.
  #
  # @note Defined to support use of external routing methods like #url_for.
  #
  # @return [Hash{String=>*}]
  #
  def env
    # noinspection RubyMismatchedReturnType
    request.env
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  module PageMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Configured results per page for the given controller/action.
    #
    # @param [Symbol, String, Hash, nil] c   Controller
    # @param [Symbol, String, nil]       a   Action
    #
    # @return [Integer]
    #
    def get_page_size(c = nil, a = nil)
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

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
    end

  end

  module ListMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Determine the number of records reported by an object.
    #
    # @param [Api::Record, Model, Array, Hash, Any, nil] value
    # @param [Integer]                                   default
    #
    # @return [Integer]               Zero indicates unknown count.
    #
    def record_count(value, default: 0)
      default = positive(default) || 1 if value.is_a?(Array)
      Array.wrap(value).sum do |v|
        res   = v.try(:totalResults)
        res ||= v.try(:records).try(:size)
        res ||= v.try(:size) unless v.is_a?(Hash)
        res || default
      end
    end

    # Extract the number of "items" reported by an object.
    #
    # (For aggregate items, this is the number of aggregates as opposed to the
    # number of records from which they are composed.)
    #
    # @param [Api::Record, Model, Array, Hash, Any, nil] value
    # @param [Integer]                                   default
    #
    # @return [Integer]               Zero indicates unknown count.
    #
    #--
    # noinspection RubyNilAnalysis, RailsParamDefResolve
    #++
    def item_count(value, default: 0)
      result   = (value.size if value.is_a?(Hash) || value.is_a?(Array))
      result ||= value.try(:totalResults)
      result ||= value.try(:records).try(:size)
      result ||= value.try(:item_count)
      result ||= value.try(:titles).try(:size)
      result || default
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
    end

  end

  module PathMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

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

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
    end

  end

  include PageMethods, ListMethods, PathMethods

  # ===========================================================================
  # :section: Paginator::PageMethods overrides
  # ===========================================================================

  public

  # Current results per page for the given controller/action (unless an
  # argument is present).
  #
  # @param [Symbol, String, Hash, nil] c   Controller
  # @param [Symbol, String, nil]       a   Action
  #
  # @return [Integer]
  #
  def get_page_size(c = nil, a = nil)
    c ? super : super(context)
  end

  # ===========================================================================
  # :section: Paginator::ListMethods overrides
  # ===========================================================================

  public

  # Determine the number of records reported by an object.
  #
  # @param [Api::Record, Model, Array, Hash, Any, nil] value
  # @param [Hash]                                      opt
  #
  # @return [Integer]               Zero indicates unknown count.
  #
  def record_count(value = nil, **opt)
    super((value || page_items), **opt)
  end

  # Extract the number of "items" reported by an object.
  #
  # @param [Api::Record, Model, Array, Hash, Any, nil] value
  # @param [Hash]                                      opt
  #
  # @return [Integer]               Zero indicates unknown count.
  #
  def item_count(value = nil, **opt)
    super((value || page_items), **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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

  # property
  #
  # @return [Paginator::Properties]
  #
  def property
    @property ||= Properties.new
  end

  # Induce all properties to acquire a value (typically for diagnostics).
  #
  # @return [Hash]
  #
  def current_properties
    Properties.keys.map { |prop| [prop, send(prop)] }.to_h
  end

  # Default results per page for the current controller/action.
  #
  # @return [Integer]
  #
  def default_page_size
    @default_page_size ||= get_page_size
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the current page number.
  #
  # @return [Integer]
  #
  def page_number
    property[:page_number] ||= 1
  end

  # Set the current page number.
  #
  # @param [Integer, nil] value
  #
  # @return [Integer]
  #
  def page_number=(value)
    Log.debug { "#{self.class}: #{__method__} #{value.inspect}" }
    property[:page_number] = value&.to_i
    page_number
  end

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
    Log.debug { "#{self.class}: #{__method__} #{value.inspect}" }
    property[:page_size] = value&.to_i
    page_size
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
    Log.debug { "#{self.class}: #{__method__} #{value.inspect}" }
    property[:page_offset] = value&.to_i
    page_offset
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the total results count if known.
  #
  # @return [Integer, nil]
  #
  def total_items
    property[:total_items]
  end

  # Set the total results count.
  #
  # @param [Integer, nil] value
  #
  # @return [Integer, nil]
  #
  def total_items=(value)
    Log.debug { "#{self.class}: #{__method__} #{value.inspect}" }
    property[:total_items] = positive(value)
  end

  # Get the number of records returned from the API for this page.
  #
  # @return [Integer, nil]
  #
  def page_records
    property[:page_records]
  end

  # Set the number of records returned from the API for this page.
  #
  # @param [Integer, nil] value
  #
  # @return [Integer, nil]
  #
  def page_records=(value)
    Log.debug { "#{self.class}: #{__method__} #{value.inspect}" }
    property[:page_records] = positive(value)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
    Log.debug { "#{self.class}: #{__method__} #{value.inspect}" }
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
    Log.debug { "#{self.class}: #{__method__} #{value.inspect}" }
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
    Log.debug { "#{self.class}: #{__method__} #{value.inspect}" }
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
    Log.debug { "#{self.class}: #{__method__} #{value.inspect}" }
    property[:prev_page] = page_path(value)
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

      make_path(context[:request].path, **prm)

    else
      list.try(:get_link, :next)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The item index of the first item on the current page.
  #
  # @return [Integer]
  #
  def first_index
    property[:first_index] ||=
      page_offset.nonzero? || ((page_number - 1) * page_size)
  end

  # Set the item index of the first item on the current page.
  #
  # @param [Integer, nil] value       If *nil*, resets to default.
  #
  # @return [Integer]
  #
  def first_index=(value)
    property[:first_index] = value&.to_i
    first_index
  end

  # The item index of the last item on the current page.
  #
  # @return [Integer]
  #
  def last_index
    property[:last_index] ||= first_index + (page_size - 1)
  end

  # Set the item index of the first item on the current page.
  #
  # @param [Integer, nil] value       If *nil*, resets to default.
  #
  # @return [Integer]
  #
  def last_index=(value)
    property[:last_index] = value&.to_i
    last_index
  end

  # The item index cursor.
  #
  # @param [Boolean] increment        If *true*, post-increment value.
  # @param [Boolean] check            If *true*, raise if out of bounds.
  #
  # @return [Integer]
  #
  def current_index(increment: false, check: false)
    (property[:current_index] ||= first_index).tap do |v|
      raise "#{__method__}: #{v} > #{last_index}" if check && (v > last_index)
      property[:current_index] += 1 if increment
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The field position of the first field for the indicated item.
  #
  # @param [Integer, nil] index       Default: `#current_index`
  #
  # @return [Integer]
  #
  def first_position(index = nil)
    index ||= current_index
    property[:first_position][index] ||= 0
  end

  # Set the field position of the first field for the indicated item.
  #
  # @param [Integer]      value
  # @param [Integer, nil] index       Default: `#current_index`
  #
  # @return [Integer]
  #
  def set_first_position(value, index = nil)
    index ||= current_index
    property[:first_position][index] = value.to_i
  end

  # The field position of the last field for the indicated item.
  #
  # @param [Integer, nil] index       Default: `#current_index`
  #
  # @return [Integer, nil]
  #
  def final_position(index = nil)
    index ||= current_index
    property[:final_position][index] ||= nil
  end

  # Set the field position of the first field for the indicated item.
  #
  # @param [Integer]      value
  # @param [Integer, nil] index       Default: `#current_index`
  #
  # @return [Integer]
  #
  def set_final_position(value, index = nil)
    index ||= current_index
    property[:final_position][index] = value.to_i
  end

  # The field position cursor.
  #
  # @param [Integer, nil] index       Default: `#current_index`
  # @param [Boolean]      increment   If *true*, post-increment value.
  # @param [Boolean]      check       If *true*, raise if out of bounds.
  #
  # @return [Integer]
  #
  def current_position(index = nil, increment: false, check: false)
    index ||= current_index
    current = property[:current_position]
    (current[index] ||= first_position(index)).tap do |v|
      if check && (final = final_position(index)) && (v > final)
        raise "#{__method__}: #{v} > #{final} [final_position(#{index})]"
      end
      current[index] += 1 if increment
    end
  end

end

__loading_end(__FILE__)
