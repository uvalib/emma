# app/controllers/sys_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class SysController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include SysConcern

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
  # :section: Formats
  # ===========================================================================

  respond_to :html #, :json, :xml

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /sys
  #
  # System information main page.
  #
  # @see #sys_index_path              Route helper
  #
  def index
    __log_activity
    __debug_route
  end

  # === POST  /sys
  # === PUT   /sys
  # === PATCH /sys
  #
  # Set application control values.
  #
  # @see #update_sys_path             Route helper
  #
  def update
    __log_activity
    __debug_route
    prm   = url_parameters
    flags = prm.delete(:flags)
    prm.merge!(flags)       if flags.present? && flags.is_a?(Hash)
    AppSettings.update(prm) if prm.present?
    # noinspection RubyResolve
    redirect_to settings_sys_path
  end

  # === GET /sys/database
  #
  # Redirects to /data.
  #
  def database
    redirect_to sys_path_for(__method__)
  end

  # === GET /sys/jobs
  #
  # Redirects to GoodJob dashboard.
  #
  def jobs
    redirect_to sys_path_for(__method__)
  end

  # === GET /sys/mailers
  #
  # Redirects to "/rails/mailers".
  #
  def mailers
    redirect_to sys_path_for(__method__)
  end

  # An endpoint is defined for each configured page that hasn't already been
  # defined here.  Pages that are not just redirects should have a template in
  # "/app/views/sys".
  #
  # @type [Array<Symbol>]
  #
  # @see file:config/locales/controllers/sys.en.yml *en.emma.sys*
  #
  PAGES = SYS_PAGES
  PAGES.excluding(*instance_methods(false)).each do |page|
    define_method(page) do
      __log_activity
      __debug_route
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get the path for a redirection from configuration.
  #
  # @param [Symbol] meth
  #
  # @return [String]
  #
  def sys_path_for(meth)
    CONTROLLER_CONFIGURATION.dig(:sys, meth, :redirect)
  end

end

__loading_end(__FILE__)
