# lib/ext/capybara-lockstep/lib/capybara-lockstep/helper.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Add CSS/SCSS to CodeStatistics

__loading_begin(__FILE__)

require 'capybara-lockstep/helper'

module Capybara
  module Lockstep
    module HelperExt

      # This override, in conjunction with the Javascript module, allows
      # 'capybara-lockstep' to work with Turbolinks.
      #
      # @return [String]
      #
      # @see file:app/assets/javascripts/vendor/capybara-lockstep.js
      #
      def capybara_lockstep_js
        super.sub(/^CapybaraLockstep.track/, '//\0')
      end

    end
  end
end

# =============================================================================
# Override gem definitions
# =============================================================================

override Capybara::Lockstep::Helper => Capybara::Lockstep::HelperExt

__loading_end(__FILE__)
