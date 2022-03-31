# app/decorators/base_collection_decorator/pagination.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods pagination of Model instance lists.
#
module BaseCollectionDecorator::Pagination

  include BaseDecorator::Pagination

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
