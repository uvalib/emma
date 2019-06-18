# app/controllers/home_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Home pages.
#
# @see app/views/home
#
# == Usage Notes
# The endpoints implemented by this controller do not require authentication of
# the requester because the methods/views react according to the identity
# associated with the current session.
#
class HomeController < ApplicationController

  include ApiConcern
  include SessionConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  prepend_before_action :session_check

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  append_around_action :session_update

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /home
  # The main application page.
  #
  # == Implementation Notes
  # There is no app/views/home/index.html.erb; this method renders the user
  # dashboard for an authenticated session or the welcome screen otherwise.
  #
  def index
    if current_user
      render template: 'home/dashboard'
    else
      render template: 'home/welcome'
    end
  end

  # == GET /home/welcome
  # The main application page for anonymous users.
  #
  def welcome
  end

  # == GET /home/dashboard
  # The main application page for authenticated users.
  #
  def dashboard
    @item, @pref = fetch_my_account
  end

end

__loading_end(__FILE__)
