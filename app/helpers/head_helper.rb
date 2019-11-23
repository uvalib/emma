# app/helpers/head_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting document "<head>" entries.
#
module HeadHelper

  # Include the submodules defined in "app/helpers/head_helper/*.rb".
  #
  # @param [Module] base
  #
  def self.included(base)
    __included(base, '[HeadHelper]')
    if in_debugger?
      include_submodules(base, __FILE__)
    else
      include_submodules(base)
    end
  end

end

__loading_end(__FILE__)
