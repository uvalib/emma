# app/controllers/concerns/tool_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/tool" controller.
#
module ToolConcern

  extend ActiveSupport::Concern

  include ToolHelper

  include SerializationConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
