# app/helpers/layout_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper.
#
module LayoutHelper

  def self.included(base)
    __included(base, '[LayoutHelper]')
  end

  # ===========================================================================
  # :section: Load submodules
  # ===========================================================================

  begin
    prev_constants = constants(false)
    require_subdir(__FILE__)
    (constants(false) - prev_constants).each do |name|
      eval "include #{name} if #{name}.is_a?(Module)"
    end
  end

end

__loading_end(__FILE__)
