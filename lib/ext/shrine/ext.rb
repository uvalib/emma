# lib/ext/shrine/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Shrine gem.

__loading_begin(__FILE__)

# When *true* invocation of each low-level IO operation triggers a log entry.
#
# @type [TrueClass, FalseClass]
#
DEBUG_SHRINE = true?(ENV['DEBUG_SHRINE']) || true # TODO: delete
#DEBUG_SHRINE = true?(ENV['DEBUG_SHRINE']) # TODO: restore

require 'shrine'
require_subdirs(__FILE__)

__loading_end(__FILE__)
