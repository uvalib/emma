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

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include Devise::Controllers::StoreLocation
      # :nocov:
    end

    # =========================================================================
    # :section: Devise::Controllers::StoreLocation overrides
    # =========================================================================

    public

    # Replace "user_return_to" with "app.current_path".
    #
    # @param [*] resource_or_scope
    #
    def stored_location_key_for(resource_or_scope)
      scope = resource_or_scope.presence
      scope &&= Devise::Mapping.find_scope!(scope)
      (!scope || (scope == :user)) ? 'app.current_path' : "#{scope}_return_to"
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Devise::Controllers::StoreLocation =>
         Devise::Controllers::StoreLocationExt

__loading_end(__FILE__)
