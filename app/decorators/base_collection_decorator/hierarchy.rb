# app/decorators/base_collection_decorator/hierarchy.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting the hierarchical display of model records.
#
# @note In use with Search items but untested with any other Model class.
#
module BaseCollectionDecorator::Hierarchy

  include BaseDecorator::Hierarchy

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
