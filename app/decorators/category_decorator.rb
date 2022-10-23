# app/decorators/category_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/category" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Bs::Record::CategorySummary]
#
class CategoryDecorator < BookshareDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for category: Bs::Record::CategorySummary

  # ===========================================================================
  # :section: Definitions shared with CategoriesDecorator
  # ===========================================================================

  public

  module SharedPathMethods
    include BookshareDecorator::SharedPathMethods
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module SharedGenericMethods

    include BookshareDecorator::SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::List overrides
    # =========================================================================

    public

    # Render a metadata listing of a category.
    #
    # @param [Hash, nil] pairs        Additional field mappings.
    # @param [Hash]      opt          Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def details(pairs: nil, **opt)
      opt[:pairs] = model_show_fields.merge(pairs || {})
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
    include BookshareDecorator::SharedInstanceMethods
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
    include BookshareDecorator::SharedClassMethods
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

class CategoryDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section: BaseDecorator::Links overrides
  # ===========================================================================

  public

  # Create a link to the catalog title search for the given category.
  #
  # @param [Hash] opt                 Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Usage Notes
  # BISAC categories can't be used for searching Bookshare so they are not
  # transformed into links.
  #
  def link(**opt)
    unless opt.key?(:no_link) || !object.respond_to?(:bookshare_category)
      opt[:no_link] = true if object.bookshare_category.blank?
    end
    model_link(object, **opt) { |term| h.title_index_path(categories: term) }
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item(pairs: nil, **opt)
    count = (object.try(:titleCount) if present?)
    opt[:pairs] = count ? { link => "(#{count})" } : {}
    opt[:pairs].merge!(model_index_fields)
    opt[:pairs].merge!(pairs) if pairs.present?
    super(**opt)
  end

end

__loading_end(__FILE__)
