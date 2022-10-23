# app/decorators/base_decorator/grid.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting iteration within a Model or collection.
#
module BaseDecorator::Row

  include BaseDecorator::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The #model_type of individual associated items for iteration.
  #
  # @return [Symbol]
  #
  # == Implementation Notes
  # This is a fallback definition.  A BaseDecorator subclass which supports
  # iteration should probably override this method in addition to #row_items.
  #
  def row_model_type
    model_type
  end

  # The class of individual associated items for iteration.
  #
  # @return [Class]
  #
  def row_model_class
    not_implemented 'To be defined by the subclass for single decorators'
  end

  # The collection of associated items to be presented in iterable form.
  #
  # @return [Array<Model>]
  # @return [ActiveRecord::Relation]
  # @return [ActiveRecord::Associations::CollectionAssociation]
  #
  # == Implementation Notes
  # A BaseDecorator subclass which supports iteration should override this
  # method to return the iterable items.
  #
  def row_items
    not_implemented 'Not applicable to single decorators by default'
  end

  # The total number of associated items.
  #
  # @return [Integer]
  #
  def row_items_total
    row_items.size
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The names and configurations for each possible row data column (whether
  # displayed or not).
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def row_fields
    Model.index_fields(row_model_type)
  end

  # The names of each row data column for display.
  #
  # @return [Array<Symbol>]
  #
  def row_columns
    row_fields.keys - row_skipped_columns
  end

  # The names of each row data column which is not displayed.
  #
  # @return [Array<Symbol>]
  #
  def row_skipped_columns
    []
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default number of rows per iteration.
  #
  # @type [Integer]
  #
  ROW_PAGE_SIZE = 25

  # The number of rows of associated items per iteration.
  #
  # @return [Integer]
  #
  def row_page_size
    paginator.page_size # NOTE: Maybe this can never be null (in which case ROW_PAGE_SIZE is redundant)
  end

  # Named parameters for #row_page.
  #
  # @type [Array<Symbol>]
  #
  ROW_PAGE_PARAMS = %i[rows limit].freeze

  # Get a subset of associated items.
  #
  # @param [*, nil]      rows         Default: `#row_items`.
  # @param [Integer,nil] limit        Number of rows to display.
  #
  # @return [Array<Model>]
  #
  def row_page(rows: nil, limit: nil, **)
    rows  ||= row_items
    limit ||= row_page_size
    offset  = paginator.page_offset
    if rows.is_a?(Array)
      # noinspection RubyMismatchedArgumentType
      if offset && limit
        rows = rows[offset..(offset + limit)]
      elsif offset
        rows = rows[offset..]
      elsif limit
        rows = rows.take(limit)
      end
    else
      rows = rows.offset(offset) if offset
      rows = rows.limit(limit)   if limit
    end
    Array.wrap(rows)
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
