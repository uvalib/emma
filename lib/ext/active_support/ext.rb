# lib/ext/active_support/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the ActiveSupport gem.

__loading_begin(__FILE__)

require 'active_support'
require 'active_support/core_ext'

# This is do-nothing module which is included in TrueClass and FalseClass
# to allow checking for a boolean value as `item.is_a? BoolType` in place of
# `(item.is_a? TrueClass || item.is_a? FalseClass)`.
#
# Since YARD and RBS will not recognize this as a substitute for 'Boolean' or
# 'bool', respectively, this is not intended for use with type documentation.
#
module BoolType
  [TrueClass, FalseClass].each { _1.include(self) }
end

require_subdirs(__FILE__)

__loading_end(__FILE__)
