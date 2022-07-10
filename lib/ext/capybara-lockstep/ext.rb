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

__loading_end(__FILE__)
