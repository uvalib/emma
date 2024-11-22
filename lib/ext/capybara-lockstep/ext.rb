# lib/ext/capybara-lockstep/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Special override for 'capybara-lockstep' compatibility with Turbolinks.

__loading_begin(__FILE__)

if ENV['RAILS_ENV'] == 'test'
  require 'capybara-lockstep'
  require_subdirs(__FILE__)
end

# Encapsulates setup of 'capybara-lockstep'.
#
module CapybaraLockstep

  # This status is updated in ApplicationSystemTestCase to indicate whether the
  # Javascript for 'capybara-lockstep' should be included in the `<head>` of
  # the page being rendered.
  #
  # (It just gets in the way in controller tests if displaying the contents of
  # the response body.)
  #
  # @return [Boolean]
  #
  mattr_accessor :active

end

__loading_end(__FILE__)
