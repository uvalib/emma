# app/helpers/model_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the display and creation of Model instances
# (both database items and API messages).
#
module ModelHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    include_submodules(base)
  end

end

__loading_end(__FILE__)
