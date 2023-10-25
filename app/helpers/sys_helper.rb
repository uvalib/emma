# app/helpers/sys_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the submodules defined in "app/helpers/sys_helper/*.rb".
  #
  # @param [Module] base
  #
  def self.included(base)
    __included(base, self)
    include_submodules(base)
  end

end

__loading_end(__FILE__)
