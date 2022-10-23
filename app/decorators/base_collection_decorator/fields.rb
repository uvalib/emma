# app/decorators/base_collection_decorator/fields.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting manipulation of Model instance fields for collections.
#
module BaseCollectionDecorator::Fields

  include BaseDecorator::Fields

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
