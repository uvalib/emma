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
  # @return [Array<Module>]           @see #include_submodules
  #
  def self.included(base)
    __included(base, '[HeadHelper]')
    include_submodules(base)
  end

end

__loading_end(__FILE__)
