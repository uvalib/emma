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
  # :section:
  # ===========================================================================

  respond_to :html #, :json, :xml

  # ===========================================================================
  # :section:
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

  # An endpoint is defined for each configured page.
  # @see file:config/locales/controllers/sys.en.yml *en.emma.sys*
  PAGES = SYS_PAGES
  PAGES.each do |page|
    define_method(page) do
      __log_activity
      __debug_route
    end
  end

end

__loading_end(__FILE__)
