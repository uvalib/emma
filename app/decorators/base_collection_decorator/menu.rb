# app/decorators/base_collection_decorator/menu.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting selectable lists of Model instances.
#
module BaseCollectionDecorator::Menu

  include BaseDecorator::Menu

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
