# app/helpers/layout_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting general page layout.
#
module LayoutHelper

  # Include the submodules defined in "app/helpers/layout_helper/*.rb".
  #
  # @param [Module] base
  #
  def self.included(base)

    __included(base, '[LayoutHelper]')

    include_submodules(base)

  end

end

__loading_end(__FILE__)
