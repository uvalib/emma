# test/application_system_test_case.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  BROWSER_CHOICES = %i[
    chrome
    headless_chrome
    firefox
    headless_firefox
    poltergeist
  ].freeze

  BROWSER    = :headless_firefox
  DRIVER_OPT = { screen_size: [1920, 1080] }.deep_freeze

  if BROWSER == :poltergeist
    require 'capybara/poltergeist'
    driven_by :poltergeist, **DRIVER_OPT
  else
    raise "#{BROWSER}: invalid" unless BROWSER_CHOICES.include?(BROWSER)
    driven_by :selenium, **DRIVER_OPT.merge(using: BROWSER)
  end

  include TestHelper::SystemTests

end
