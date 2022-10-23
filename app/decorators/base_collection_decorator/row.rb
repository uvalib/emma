# app/decorators/base_collection_decorator/row.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting iteration within a Model or collection.
#
module BaseCollectionDecorator::Row

  include BaseDecorator::Row

  include BaseCollectionDecorator::Common

  # ===========================================================================
  # :section: BaseDecorator::Row overrides
  # ===========================================================================

  public

  # The #model_type of individual associated items for iteration.
  #
  # @return [Symbol]
  #
  # @see BaseCollectionDecorator::SharedClassMethods#decorator_class
  #
  def row_model_type
    decorator_class.model_type
  end

  # The class of individual associated items for iteration.
  #
  # @return [Class]
  #
  def row_model_class
    object_class
  end

  # The collection of associated items to be presented in iterable form.
  #
  # @return [Array<Model>]
  # @return [ActiveRecord::Relation]
  # @return [ActiveRecord::Associations::CollectionAssociation]
  #
  def row_items
    object
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
