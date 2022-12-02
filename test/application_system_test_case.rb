# test/application_system_test_case.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'
require 'capybara-lockstep'

# Browser choices are:
#
# - :chrome
# - :chrome_headless
# - :firefox
# - :firebox_headless
#
# Chrome actually seems to have some problems (e.g., 'go_back') so it might not
# be the best choice in general.
#
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  include TestHelper::SystemTests

  if NO_JAVASCRIPT

    driven_by :rack_test

  else

    HEADLESS    = true
    BROWSER     = HEADLESS ? :headless_firefox   : :firefox
    SCREEN_SIZE = HEADLESS ? [1920, 1080].freeze : [1024, 768].freeze

    driven_by :selenium, using: BROWSER, screen_size: SCREEN_SIZE do |drv_opt|
      if BROWSER.match?(/Firefox/i)
        drv_opt.add_preference('devtools.jsonview.enabled', false)
      end
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # noinspection RbsMissingTypeSignature
  setup do
    CapybaraLockstep.active = true
  end

  # noinspection RbsMissingTypeSignature
  teardown do
    CapybaraLockstep.active = false
  end

end

# Encapsulates setup of 'capybara-lockstep'.
#
module CapybaraLockstep

  Capybara::Lockstep.debug = true?(ENV['DEBUG_LOCKSTEP'])

  # This status is updated to indicate whether or not the Javascript for
  # 'capybara-lockstep' should be included in the <head> of the page being
  # rendered.  (It just gets in the way in controller tests if displaying the
  # contents of the response body.)
  #
  # @return [Boolean]
  #
  mattr_accessor :active

end
