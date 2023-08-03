# lib/ext/cancancan/lib/cancan/controller_additions.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Down gem.

__loading_begin(__FILE__)

require 'cancan/controller_additions'

module CanCan

  module ControllerAdditionsExt

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include CanCan::ControllerAdditions
      include UserConcern
      # :nocov:
    end

    # =========================================================================
    # :section: CanCan::ControllerAdditions overrides
    # =========================================================================

    public

    def current_ability
      @current_ability ||= current_user&.ability || ::Ability.new
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override CanCan::ControllerAdditions => CanCan::ControllerAdditionsExt

__loading_end(__FILE__)
