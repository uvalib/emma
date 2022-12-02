# app/decorators/base_collection_decorator/lookup.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting bibliographic lookup and related elements.
#
module BaseCollectionDecorator::Lookup

  include BaseDecorator::Lookup

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
