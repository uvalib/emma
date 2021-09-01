# app/helpers/search_call_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting access to search call records.
#
module SearchCallHelper

  include ModelHelper
  include PaginationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default link tooltip.
  #
  # @type [String]
  #
  SEARCH_CALL_SHOW_TOOLTIP = I18n.t('emma.search_call.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_call_link(item, **opt)
    opt[:path]    = search_call_path(id: item.identifier)
    opt[:tooltip] = SEARCH_CALL_SHOW_TOOLTIP
    model_link(item, **opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render details of a search call.
  #
  # @param [SearchCall] item
  # @param [Hash, nil]  pairs         Additional field mappings.
  # @param [Hash]       opt           Passed to #search_call_field_values and
  #                                     #model_details.
  #
  def search_call_details(item, pairs: nil, **opt)
    opt[:model] = model_for(item)
    fv_opt, opt = partition_hash(opt, :columns, :filter)
    opt[:pairs] = search_call_field_values(item, **fv_opt)
    opt[:pairs].merge!(pairs) if pairs.present?
    count = opt[:pairs].size
    append_classes!(opt, "columns-#{count}") if count.positive?
    model_details(item, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [SearchCall] item
  # @param [Hash, nil]  pairs         Additional field mappings.
  # @param [Hash]       opt           Passed to #model_list_item.
  #
  def search_call_list_item(item, pairs: nil, **opt)
    opt[:model] = model = item && model_for(item) || :search_call
    opt[:pairs] = index_fields(model).merge(pairs || {})
    model_list_item(item, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render search calls as a table.
  #
  # @param [SearchCall, Array<SearchCall>] list
  # @param [Hash]                          opt   Passed to #model_table except:
  #
  # @option [Boolean] :extended       Indicate that this is the "extended"
  #                                     version of the table which replaces
  #                                     columns holding JSON data with columns
  #                                     holding each JSON sub-field.
  #
  def search_call_table(list, **opt)
    prepend_classes!(opt, 'extended') if opt.delete(:extended)
    opt[:model] ||= :search_call
    opt[:thead] ||= search_call_table_headings(list, **opt)
    opt[:tbody] ||= search_call_table_entries(list, **opt)
    model_table(list, **opt)
  end

  # Render one or more entries for use within a <tbody>.
  #
  # @param [SearchCall, Array<SearchCall>] list
  # @param [Hash]                          opt   Passed to #model_table_entries
  #
  def search_call_table_entries(list, **opt)
    # noinspection RubyMismatchedParameterType
    model_table_entries(list, **opt) do |item, **row_opt|
      search_call_table_entry(item, **row_opt)
    end
  end

  # Render a single entry for use within a table of items.
  #
  # @param [SearchCall] item
  # @param [Hash]       opt           Passed to #model_table_entry
  #
  def search_call_table_entry(item, **opt)
    # noinspection RubyMismatchedParameterType
    model_table_entry(item, **opt) do |b_item, **b_opt|
      search_call_columns(b_item, **b_opt)
    end
  end

  # Render column headings for a search call table.
  #
  # @param [SearchCall, Array<SearchCall>] item
  # @param [Hash]                          opt  Passed to #model_table_headings
  #
  def search_call_table_headings(item, **opt)
    # noinspection RubyMismatchedParameterType
    model_table_headings(item, **opt) do |b_item, **b_opt|
      search_call_columns(b_item, **b_opt)
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  protected

  # Specified field selections from the given User instance.
  #
  # @param [SearchCall, Hash, nil] item
  # @param [Hash]                  opt    Passed to #model_field_values
  #
  def search_call_field_values(item, **opt)
    return {} unless item.is_a?(SearchCall) || item.is_a?(Hash)
    v_opt = nil
    model_field_values(item, **opt).transform_values! do |attr_value|
      if attr_value.blank? && !attr_value.is_a?(FalseClass)
        EM_DASH

      elsif attr_value.is_a?(Hash)
        html_div(class: 'key-value-pair') do
          v_opt ||= { separator: search_call_connector }
          attr_value.map do |field, value|
            search_call_field(field) << search_call_value(value, **v_opt)
          end
        end

      elsif attr_value.is_a?(Array)
        # TODO: not being seen yet -- shouldn't it be seen for JSON fields?
        v = strip_quotes(attr_value)
        v_opt ||= { separator: search_call_connector }
        search_call_value(v, **v_opt)

      elsif attr_value.is_a?(String) && attr_value.start_with?('["')
        # TODO: why is the JSON type field converting to String for these?
        v = attr_value.delete_prefix('["').delete_suffix('"]').split(/", *"/)
=begin
        v_opt ||= { separator: search_call_connector }
=end
        v_opt ||= { separator: HTML_BREAK }
        search_call_value(v, **v_opt)

      elsif attr_value.is_a?(String)
        # TODO: ?
        v = strip_quotes(attr_value)
        search_call_value(v)

      else
        attr_value
      end
    end
  end

  # Element containing a field name.
  #
  # @param [String, Symbol] field
  # @param [Hash]           opt       Passed to #html_span except for:
  #
  # @option opt [Hash] :name          Passed to name #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_call_field(field, **opt)
    f_opt = { class: 'name' }
    name  = opt.delete(:name) and merge_html_options!(f_opt, name)
    prepend_classes!(opt, 'key')
    opt[:'data-value'] = field
    html_span(opt) do
      html_span(field, f_opt) << ': '.html_safe
    end
  end

  # Element containing one or more field values.
  #
  # @param [String, Numeric, Array] value
  # @param [Hash]                   opt     Passed to #html_span except for:
  #
  # @option opt [Hash]   :item              Passed to item #html_span.
  # @option opt [String] :separator         Default: `#search_call_connector`.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_call_value(value, **opt)
    v_opt = { class: 'item' }
    item  = opt.delete(:item) and merge_html_options!(v_opt, item)
    sep   = opt.delete(:separator)
    value =
      Array.wrap(value).map do |v|
        v_opt[:'data-value'] = v
        if v == NULL_SEARCH
          star_opt = append_classes(v_opt, 'star')
          star_opt[:title] = 'Null search' # TODO: I18n
          html_span(ASTERISK, star_opt)
        elsif v.is_a?(String) && v.match?(/\s/)
          quote(html_span(v, v_opt))
        else
          html_span(v, v_opt)
        end
      end
    prepend_classes!(opt, 'value')
    html_span(opt) do
      if value.size > 1
        safe_join(value, (sep || search_call_connector))
      else
        value
      end
    end
  end

  # Element separating multiple values.
  #
  # @param [Hash] opt                 Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Implementation Notes
  # The element is surrounded by spaces so that a compound value element can be
  # copied and pasted legibly.
  #
  def search_call_connector(**opt)
    prepend_classes!(opt, 'or')
    connector = html_span('OR', opt) # TODO: I18n
    " #{connector} ".html_safe
  end

  # search_call_columns
  #
  # @param [SearchCall, nil] item
  # @param [Hash]            opt      Passed to #search_call_field_values
  #
  # @return [Hash{Symbol=>*}]
  #
  def search_call_columns(item = nil, **opt)
    search_call_field_values(item, **opt)
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
