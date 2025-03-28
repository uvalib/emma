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

  # System information pages configuration.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see "en.emma.page.about.action"
  #
  ABOUT_CONFIG = CONTROLLER_CONFIGURATION.dig(:about, :action).deep_freeze

  # System information pages (including for :index).
  #
  # @type [Array<Symbol>]
  #
  ABOUT_PAGES = ABOUT_CONFIG.keys.freeze

  # System information pages available to anonymous users.
  #
  # @type [Array<Symbol>]
  #
  ANON_ABOUT_PAGES = ABOUT_CONFIG.reject { |_, prop| prop[:role] }.keys.freeze

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
