# app/helpers/head_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting document "<head>" entries.
#
module HeadHelper

  def self.included(base)
    __included(base, '[HeadHelper]')
  end

  # ===========================================================================
  # :section: Include submodules
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
