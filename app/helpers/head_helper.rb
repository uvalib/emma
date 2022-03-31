# app/helpers/head_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting document '<head>' entries.
#
module HeadHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the submodules defined in "app/helpers/head_helper/*.rb".
  #
  # @param [Module] base
  #
  def self.included(base)
    __included(base, self)
    include_submodules(base)
  end

end

__loading_end(__FILE__)
