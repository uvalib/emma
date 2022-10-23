# app/decorators/base_collection_decorator/controls.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common methods supporting display of Model instances (both database items and
# API messages).
#
module BaseCollectionDecorator::Controls

  include BaseDecorator::Controls

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
