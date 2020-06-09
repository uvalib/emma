# lib/ext/devise/lib/devise/controllers/store_location.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Devise gem.

__loading_begin(__FILE__)

require 'devise/controllers/store_location'

module Devise

  # Override definitions to be prepended to Devise::Controllers::StoreLocation.
  #
  module Controllers::StoreLocationExt

    # Replace "user_return_to" with "current_path".
    #
    # @param [*] resource_or_scope
    #
    # This method overrides:
    # @see Devise::Controllers::StoreLocation#stored_location_key_for
    #
    def stored_location_key_for(resource_or_scope)
      scope = Devise::Mapping.find_scope!(resource_or_scope)
      (scope == :user) ? 'current_path' : "#{scope}_return_to"
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Devise::Controllers::StoreLocation =>
         Devise::Controllers::StoreLocationExt

__loading_end(__FILE__)
