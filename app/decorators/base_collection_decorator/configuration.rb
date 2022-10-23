# app/decorators/base_collection_decorator/configuration.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model/controller related configuration information relative to model_type.
#
module BaseCollectionDecorator::Configuration

  include BaseDecorator::Configuration

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
