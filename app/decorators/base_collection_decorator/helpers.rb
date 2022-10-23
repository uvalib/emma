# app/decorators/base_collection_decorator/helpers.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions to support inclusion of helpers.
#
module BaseCollectionDecorator::Helpers

  include BaseDecorator::Helpers

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
