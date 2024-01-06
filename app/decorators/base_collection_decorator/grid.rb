# app/decorators/base_collection_decorator/grid.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting grid-based displays.
#
module BaseCollectionDecorator::Grid

  include BaseDecorator::Grid

  include BaseCollectionDecorator::Common
  include BaseCollectionDecorator::Row

  # ===========================================================================
  # :section: BaseDecorator::Grid overrides
  # ===========================================================================

  public

  # The collection of items to be presented in grid form.
  #
  # @param [Hash] opt                 Modifies *object* results.
  #
  # @return [Array<Model>]
  # @return [ActiveRecord::Relation]
  # @return [ActiveRecord::Associations::CollectionAssociation]
  #
  # @see BaseCollectionDecorator::Row#row_items
  #
  def grid_row_items(**opt)
    # noinspection RubyMismatchedReturnType
    row_items(**opt)
  end

  # The #model_type of individual associated items for iteration.
  #
  # @return [Symbol]
  #
  # @see BaseCollectionDecorator::Row#row_model_type
  #
  def grid_row_model_type
    row_model_type
  end

  # The class of individual associated items for iteration.
  #
  # @return [Class]
  #
  def grid_row_model_class
    row_model_class
  end

  # ===========================================================================
  # :section: BaseDecorator::Grid methods for individual items
  # ===========================================================================

  public

  %i[grid_row grid_row_controls grid_item].each do |meth|
    define_method(meth) do |**opt|
      single_item_method(meth) or super(**opt)
    end
  end

  # ===========================================================================
  # :section: BaseDecorator::Grid methods for individual items
  # ===========================================================================

  protected

  # Log the fact that a method intended for a single-item decorator has been
  # invoked by a collection decorator.
  #
  # @param [Symbol] meth              Calling method.
  #
  # @return [nil]
  #
  def single_item_method(meth)
    Log.warn { "#{meth}: inappropriate for #{self} -- probably an error" }
    raise
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
