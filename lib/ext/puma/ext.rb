# lib/ext/puma/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Puma gem which are only activated by ENV['DEBUG_PUMA'].

__loading_begin(__FILE__)

require 'puma'
require 'puma/server'
require_subdirs(__FILE__)

__loading_end(__FILE__)
