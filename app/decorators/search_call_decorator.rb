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
    html_span(**opt) do
      html_span(field, **f_opt) << ': '.html_safe
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
          html_span(ASTERISK, **star_opt)
        elsif v.is_a?(String) && v.match?(/\s/)
          quote(html_span(v, **v_opt))
        else
          html_span(v, **v_opt)
        end
      end
    prepend_css!(opt, 'value')
    html_span(**opt) do
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
  # === Implementation Notes
  # The element is surrounded by spaces so that a compound value element can be
  # copied and pasted legibly.
  #
  def search_call_connector(**opt)
    prepend_css!(opt, 'or')
    connector = html_span('OR', **opt) # TODO: I18n
    " #{connector} ".html_safe
  end

end

__loading_end(__FILE__)
