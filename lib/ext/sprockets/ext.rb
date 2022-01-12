# lib/ext/sprockets/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Sprockets gem.

__loading_begin(__FILE__)

if rake_task?
  require 'sprockets'
  require_subdirs(__FILE__)
end

__loading_end(__FILE__)
