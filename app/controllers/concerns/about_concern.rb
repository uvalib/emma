# app/controllers/concerns/about_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for application information.
#
module AboutConcern

  extend ActiveSupport::Concern

  include ApplicationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # System information pages (including for :index).
  #
  # @type [Array<Symbol>]
  #
  # @see "en.emma.page.about.action"
  #
  ABOUT_PAGES = CONTROLLER_CONFIGURATION.dig(:about, :action).keys.freeze

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
