# app/decorators/search_call_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/search_call" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [SearchCall]
#
class SearchCallDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for SearchCall

  # ===========================================================================
  # :section: Definitions shared with SearchCallsDecorator
  # ===========================================================================

  public

  module SharedPathMethods
    include BaseDecorator::SharedPathMethods
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module SharedGenericMethods

    include BaseDecorator::SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::List overrides
    # =========================================================================

    public

    # Render details of a search call.
    #
    # @param [Hash, nil] pairs        Additional field mappings.
    # @param [Hash]      opt          Passed to super except:
    #
    # @option opt [String, Symbol, Array<String,Symbol>] :columns
    # @option opt [String, Regexp, Array<String,Regexp>] :filter
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see #model_field_values
    #
    def details(pairs: nil, **opt)
      fv_opt      = extract_hash!(opt, :columns, :filter)
      opt[:pairs] = model_field_values(**fv_opt).merge!(pairs || {})
      count       = opt[:pairs].size
      append_css!(opt, "columns-#{count}") if count.positive?
      super(**opt)
    end

    # Render a single entry for use within a list of items.
    #
    # @param [Hash, nil] pairs        Additional field mappings.
    # @param [Hash]      opt          Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def list_item(pairs: nil, **opt)
      opt[:pairs] = model_index_fields.merge(pairs || {})
      super(**opt)
    end

  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module SharedInstanceMethods
    include BaseDecorator::SharedInstanceMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
  module SharedClassMethods
    include BaseDecorator::SharedClassMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Cause definitions to be included here and in the associated collection
  # decorator via BaseCollectionDecorator#collection_of.
  #
  module SharedDefinitions
    def self.included(base)
      base.include(SharedInstanceMethods)
      base.extend(SharedClassMethods)
    end
  end

end

class SearchCallDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section: BaseDecorator::Links overrides
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def link(**opt)
    opt[:path] = show_path(id: object.identifier)
    super(**opt)
  end

  # ===========================================================================
  # :section: BaseDecorator::Table overrides
  # ===========================================================================

  protected

  # Specified field selections from the given SearchCall instance.
  #
  # @param [SearchCall, Hash, nil] item   Default: `#object`
  # @param [Hash]                  opt    Passed to super.
  #
  # @return [Hash{String=>ActiveSupport::SafeBuffer}]
  #
  def model_field_values(item = nil, **opt)
    v_opt = nil
    super.transform_values! do |attr_value|
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
        #v_opt ||= { separator: search_call_connector }
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

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
    prepend_css!(opt, 'key')
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
    v_opt  = { class: 'item' }
    item   = opt.delete(:item) and merge_html_options!(v_opt, item)
    sep    = opt.delete(:separator)
    result =
      Array.wrap(value).map do |v|
        v_opt[:'data-value'] = v
        if v == SearchTerm::NULL_SEARCH
          star_opt = append_css(v_opt, 'star')
          star_opt[:title] = 'Null search' # TODO: I18n
          html_span(ASTERISK, star_opt)
        elsif v.is_a?(String) && v.match?(/\s/)
          quote(html_span(v, v_opt))
        else
          html_span(v, v_opt)
        end
      end
    prepend_css!(opt, 'value')
    html_span(opt) do
      if result.size > 1
        safe_join(result, (sep || search_call_connector))
      else
        result
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
    prepend_css!(opt, 'or')
    connector = html_span('OR', opt) # TODO: I18n
    " #{connector} ".html_safe
  end

end

__loading_end(__FILE__)
