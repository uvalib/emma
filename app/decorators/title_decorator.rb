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
  # :section:
  # ===========================================================================

  public

  module Paths
    include BookshareDecorator::Paths
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module Methods
    include BookshareDecorator::Methods
  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module InstanceMethods
    include BookshareDecorator::InstanceMethods, Paths, Methods
  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
  module ClassMethods
    include BookshareDecorator::ClassMethods, Paths, Methods
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
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a metadata listing of an periodical.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details(pairs: nil, **opt)
    opt[:pairs] = model_show_fields.merge(pairs || {})
    super(**opt)
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
    opt[:pairs] = model_index_fields.merge(pairs || {})
    super(**opt)
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

end

__loading_end(__FILE__)
