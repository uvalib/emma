# app/decorators/base_collection_decorator/retrievals.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting managed downloads.
#
module BaseCollectionDecorator::Retrievals

  include BaseDecorator::Retrieval

  include BaseCollectionDecorator::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
