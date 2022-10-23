# app/decorators/title_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/title" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Bs::Record::TitleMetadataSummary]
#
class TitleDecorator < BookshareDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for title: Bs::Message::TitleMetadataDetail, and: [Title,
    Bs::Record::TitleMetadataSummary, Bs::Record::ReadingListTitle]

  # ===========================================================================
  # :section: Definitions shared with TitlesDecorator
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

    # Render a metadata listing of an periodical.
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

class TitleDecorator

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
  # :section: BookshareDecorator overrides
  # ===========================================================================

  public

  # Catalog item search links.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def search_links(**opt)
    opt[:field] ||= :keyword
    super(**opt)
  end

  # A link to the catalog item search results index page for the given term(s).
  #
  # @param [String] terms
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def search_link(terms, **opt)
    opt[:field] ||= :keyword
    super(terms, **opt)
  end

  # ===========================================================================
  # :section: BookshareDecorator overrides
  # ===========================================================================

  protected

  # form_action_link
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_action_link(**opt)
    unless opt[:action] == :new
      opt[:id] ||= context[:bookshareId] || object.try(:bookshareId)
    end
    super(**opt)
  end

  # form_target_description
  #
  # @param [Symbol] action
  #
  # @return [String]
  #
  def form_target_description(action: nil, **)
    case action
      when :edit, :delete then 'catalog title metadata' # TODO: I18n
      else                     'a catalog title'        # TODO: I18n
    end
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # details_container
  #
  # @param [Array]         added      Optional elements after the details.
  # @param [Array<Symbol>] skip       Display aspects to avoid.
  # @param [Hash]          opt        Passed to super
  # @param [Proc]          block      Passed to super
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details_container(*added, skip: [], **opt, &block)
    skip = Array.wrap(skip)
    added.prepend(cover) unless skip.include?(:cover)
    super(*added, **opt, &block)
  end

end

__loading_end(__FILE__)
