# app/controllers/concerns/sys_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for system information.
#
module SysConcern

  extend ActiveSupport::Concern

  include ApplicationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # System information pages (except for :index).
  #
  # @type [Array<Symbol>]
  #
  SYS_PAGES =
    CONTROLLER_CONFIGURATION[:sys].except(:index, :view).map { |k, v|
      k if v.is_a?(Hash) && v[:_endpoint]
    }.compact.freeze

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
