# lib/emma/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# General support methods.
#
module Emma::Common

  # @private
  def self.included(base)
    base.send(:extend, self)
  end

  require_submodules(__FILE__)
  include_submodules(self)

end

__loading_end(__FILE__)
