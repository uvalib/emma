# app/helpers/about_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'loofah'

# View helper methods for rendering application information.
#
module AboutHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the submodules defined in "app/helpers/about_helper/*.rb".
  #
  # @param [Module] base
  #
  def self.included(base)
    __included(base, self)
    include_submodules(base)
  end

end

__loading_end(__FILE__)
