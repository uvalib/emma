# lib/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_files(__FILE__, 'ext/*.rb')
require_files(__FILE__, 'ext/*/ext.rb')

__loading_end(__FILE__)
