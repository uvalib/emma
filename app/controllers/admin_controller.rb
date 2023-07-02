# app/controllers/admin_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class AdminController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include AdminConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_admin!

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html #, :json, :xml

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /admin
  #
  # Administrative main page.
  #
  # @see #admin_index_path            Route helper
  #
  def index
    __log_activity
    __debug_route
  end

  # === POST  /admin
  # === PUT   /admin
  # === PATCH /admin
  #
  # Set application control values.
  #
  # @see #update_admin_path           Route helper
  #
  def update
    __log_activity
    __debug_route
    prm   = url_parameters
    flags = prm.delete(:flags)
    prm.merge!(flags)       if flags.present? && flags.is_a?(Hash)
    AppSettings.update(prm) if prm.present?
    # noinspection RubyResolve
    redirect_to settings_admin_path
  end

  # An endpoint is defined for each configured page.
  # @see file:config/locales/controllers/admin.en.yml *en.emma.admin*
  PAGES = ADMIN_PAGES
  PAGES.each do |page|
    define_method(page) do
      __log_activity
      __debug_route
    end
  end

end

__loading_end(__FILE__)
