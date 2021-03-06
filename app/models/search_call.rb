# app/models/search_call.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for a specific search call event instance.
#
class SearchCall < ApplicationRecord

  include Emma::Debug
  include Model

  has_and_belongs_to_many :search_results

  belongs_to :user, optional: true

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  resourcify

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Each JSON-structured column of 'search_calls'.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  JSON_COLUMN_CONFIG =
    {
      result: {
        keys: {
          total: { type: :integer },
          count: { type: :integer },
        },
        params: {} # Filled below.
      },

      query:  {
        keys: {},  # Filled below.
        params: {
          author:  :creator,
          keyword: :q,
          query:   :q,
        }
      },

      sort:   {
        keys: {
          order:     { type: :string },
          direction: { type: :string },
        },
        params: {} # Filled below.
      },

      filter: {
        keys:   {},  # Filled below.
        params: {
          fmt: :format,
        }
      },

      page:   {
        keys: {
          limit:  { type: :integer },
          start:  { type: :integer }, # TODO: ???
          offset: { type: :integer }, # TODO: ???
          number: { type: :integer },
        },
        params: {
          page: :number, # TODO: this needs to go away
          size: :limit,
        }
      }

    }.tap { |json_columns|
      reserved_keys = json_columns.keys
      reserved_keys += json_columns.values.flat_map { |cfg| cfg[:keys]&.keys }

      # Extract keys from "en.emma.search_type" but transformed based on the
      # translations defined in the :params element.
      json_columns[:query][:keys] =
        SearchTermsHelper::QUERY_PARAMETERS[:search].map { |type|
          key = json_columns.dig(:query, :params, type) || type
          next if reserved_keys.include?(type)
          [key, { type: :string }]
        }.compact.to_h.tap { |hash| reserved_keys += hash.keys }


      # Extract keys from "en.emma.search_filters".
      f_keys   = json_columns[:filter][:keys]
      f_params = json_columns[:filter][:params]
      LayoutHelper::SearchFilters::SEARCH_MENU_BASE.each_pair do |key, config|
        key = f_params[key] || key
        next if reserved_keys.include?(key) || key.match?(/periodical/)
        f_keys[key] = { type: (config[:multiple] ? :array : :string) }
        config[:url_parameter]&.then { |param| f_params[param.to_sym] = key }
      end

      # For convenience, each of the :params elements is back-filled so that
      # the JSON field itself can be used as a URL parameter as well as the
      # compound form "COLUMN_FIELD".
      json_columns.each_pair do |column, config|
        config[:keys].keys.each do |key|
          [key, :"#{column}_#{key}"].each do |param|
            config[:params][param] = key
          end
        end
      end
    }.deep_freeze

  # Database fields holding attributes of the search that was performed.
  #
  # @type [Array<Symbol>]
  #
  JSON_COLUMNS = JSON_COLUMN_CONFIG.keys.freeze

=begin
  # URL parameters which map into the :result attribute.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  RESULT_PARAMETERS = {
    total: %i[result total],
    count: %i[result count],
  }.deep_freeze

  # JSON keys valid within the :result attribute.
  #
  # @type [Array<Symbol>]
  #
  RESULT_JSON_FIELDS = JSON_COLUMN_CONFIG[:result][:keys].keys.freeze

  # URL parameters which map into the :sort attribute.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  SORT_PARAMETERS = {
    sort:       %i[sort order],
    sort_order: %i[sort order],
    direction:  %i[sort direction],
  }.deep_freeze

  # JSON keys valid within the :sort attribute.
  #
  # @type [Array<Symbol>]
  #
  SORT_JSON_FIELDS = JSON_COLUMN_CONFIG[:sort][:keys].keys.freeze

  # URL parameters which map into the :page attribute.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  PAGE_PARAMETERS = {
    page:       %i[page number],
    limit:      %i[page limit],
    size:       %i[page limit],
    page_size:  %i[page limit],
    start:      %i[page start],
    offset:     %i[page offset],
  }.deep_freeze

  # JSON keys valid within the :page attribute.
  #
  # @type [Array<Symbol>]
  #
  PAGE_JSON_FIELDS = JSON_COLUMN_CONFIG[:page][:keys].keys.freeze

  # URL parameters which map into the :query attribute.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  QUERY_PARAMETERS =
    SearchTermsHelper::QUERY_PARAMETERS[:search].map { |type|
      json_field = type.to_s.underscore.to_sym
      next if JSON_COLUMNS.include?(json_field)
      path = %i[query]
      case json_field
        when :author          then path << :creator
        when :keyword, :query then path << :q
        else                       path << json_field
      end
      [type.to_sym, path]
    }.compact.to_h.deep_freeze

  # JSON keys valid within the :query attribute.
  #
  # @type [Array<Symbol>]
  #
  QUERY_JSON_FIELDS = JSON_COLUMN_CONFIG[:query][:keys].keys.freeze

  # URL parameters which map into attributes other than :filter.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  NON_FILTER_PARAMETERS =
    {}.merge(
      QUERY_PARAMETERS, PAGE_PARAMETERS, SORT_PARAMETERS, RESULT_PARAMETERS
    ).deep_freeze

  # URL parameters which map into the :filter attribute.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  FILTER_PARAMETERS =
    LayoutHelper::SearchFilters::SEARCH_MENU_BASE.flat_map { |field, config|
      json_field = field.to_s.underscore.to_sym
      next if JSON_COLUMNS.include?(json_field)
      next if json_field.match?(/periodical/)
      [field, config[:url_parameter]].map do |f|
        next if (f = f&.to_sym).blank?
        [f, [:filter, json_field]] unless NON_FILTER_PARAMETERS.include?(f)
      end
    }.compact.to_h.deep_freeze

  # JSON keys valid within the :filter attribute.
  #
  # @type [Array<Symbol>]
  #
  FILTER_JSON_FIELDS = JSON_COLUMN_CONFIG[:filter][:keys].keys.freeze
=end

  # JSON fields defined for each JSON column.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  JSON_COLUMN_FIELDS =
    JSON_COLUMN_CONFIG.transform_values { |cfg| cfg[:keys].keys }.freeze

  # JSON sub-field parameters for each JSON column.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  JSON_COLUMN_PARAMETERS =
    JSON_COLUMN_CONFIG.map { |column, config|
      params =
        config[:params].map { |param, key|
          [param, [column, key]]
        }.to_h
      [column, params]
    }.to_h

  # URL parameters which map into attributes.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  PARAMETER_MAP =
    JSON_COLUMN_PARAMETERS.values.flat_map(&:to_a).sort.uniq.to_h

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Hash, nil] attributes
  #
  def initialize(attributes = nil)
    __debug_items(binding)
    super # TODO: ???
  end

  # Produce a value that can be used for SearchController URL parameters.
  #
  # @return [Hash]
  #
  def as_search_parameters
    h = JSON_COLUMNS.map { |c| [c, (self[c] || {})] }.to_h
    {
      identifier:           h.dig(:query,  :identifier),
      title:                h.dig(:query,  :title),
      creator:              h.dig(:query,  :creator),
      publisher:            h.dig(:query,  :publisher),
      q:                    h.dig(:query,  :q),
      sortOrder:            h.dig(:sort,   :order),
      direction:            h.dig(:sort,   :direction),
      limit:                h.dig(:page,   :limit),
      start:                h.dig(:page,   :start),
      offset:               h.dig(:page,   :offset),
      accessibilityFeature: h.dig(:filter, :a11y_feature),
      braille:              h.dig(:filter, :braille),
      contentType:          h.dig(:filter, :content_type),
      country:              h.dig(:filter, :country),
      fmt:                  h.dig(:filter, :format),
      formatFeature:        h.dig(:filter, :format_feature),
      language:             h.dig(:filter, :language),
      repository:           h.dig(:filter, :repository),
    }.compact
  end

  # ===========================================================================
  # :section: ActiveRecord overrides
  # ===========================================================================

  public

  # Update database fields...
  #
  # @param [SearchCall, ActionController::Parameters, Hash, nil] opt
  #
  # @return [void]
  #
  # This method overrides:
  # @see ActiveModel::AttributeAssignment#assign_attributes
  #
  #--
  # noinspection RubyNilAnalysis, RubyYardParamTypeMatch
  #++
  def assign_attributes(opt)
    __debug_items(binding)
    opt = opt.is_a?(SearchCall) ? opt.attributes : map_parameters(opt)
    opt.delete(:id)
    __debug_items(__method__, opt)
    super(opt)
  rescue => error # TODO: remove - testing
    Log.warn { "#{__method__}: #{error.class}: #{error.message}"}
    raise error
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Transform URL parameters into attribute settings.
  #
  # @param [ActionController::Parameters, Hash, nil] params
  #
  # @return [Hash{Symbol=>String,Array<String>}]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def map_parameters(params)
    result = JSON_COLUMN_CONFIG.transform_values { Hash.new }
    params = params.params      if params.respond_to?(:params)
    params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
    params&.each_pair do |k, v|
      case k
        when :user,   :user_id then result[:user_id] = get_user_id(v)
        when :result, :results then result[:result]  = get_counts(v)
        else
          if (column, json_field = PARAMETER_MAP[k])
            result[column][json_field] = [*result[column][json_field], *v]
          elsif field_names.include?(k)
            result[k] = [*result[k], *v]
          else
            __debug_items(__method__) { { "ignored #{k}" => v } }
          end
      end
    end
    reject_blanks(result, true).sort.to_h
  end

  # Extract a 'users' table index from the given item.
  #
  # @param [User, String, Numeric] src
  #
  # @return [Integer]
  # @return [nil]
  #
  def get_user_id(src)
    User.find_id(src)
  end

  # Generate a :record attribute value from the given item.
  #
  # @param [Api::Message, Hash, Array, Numeric, String] src
  #
  # @return [Hash{Symbol=>Integer}]
  #
  def get_counts(src)
    case src
      when Hash            then count, total = src.values_at(:count, :total)
      when Array           then count = total = src.size
      when String, Numeric then count = total = positive(src)
      else
        count = src.try(:records)&.size
        total = src.try(:totalResults)
    end
    total ||= count
    count = nil if count == total
    { total: total, count: count }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Local options consumed by #search_records.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_RECORDS_OPTIONS = Upload::SEARCH_RECORDS_OPTIONS

  def search_records(*identifiers, **opt)
    local_opt, opt = partition_hash(opt, *SEARCH_RECORDS_OPTIONS)
    # TODO: search_records???
  end

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # Generate the SQL statement for dynamically creating a derived table with
  # JSON fields expanded into columns.
  #
  # @param [String, Hash, nil] extra
  # @param [Hash]              opt
  #
  # @return [String]
  #
  # @see ApplicationRecord#sql_extended_table
  #
  def self.sql_extended_table(extra = nil, **opt)
    opt[:field_map] ||= JSON_COLUMN_FIELDS
    super(extra, **opt)
  end

  # Generate condition(s) for a WHERE clause.
  #
  # @param [Hash] opt                 Field assertions.
  #
  # @return [String]
  #
  # @see ApplicationRecord#sql_where_clause
  #
  def self.sql_where_clause(**opt)
    opt[:field_map] ||= JSON_COLUMN_FIELDS
    opt[:param_map] ||= JSON_COLUMN_PARAMETERS
    super(**opt)
  end

end

__loading_end(__FILE__)
