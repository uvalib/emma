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
  include ParamsConcern
  include SessionConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Not applicable.

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

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
    __debug { "HOME #{__method__} | params = #{params.inspect}" }
    if current_user
      @item, @pref = fetch_my_account
      render template: 'home/dashboard'
    else
      render template: 'home/welcome'
    end
  end

  # == GET /home/welcome
  # The main application page for anonymous users.
  #
  def welcome
    __debug { "HOME #{__method__} | params = #{params.inspect}" }
  end

  # == GET /home/dashboard
  # The main application page for authenticated users.
  #
  def dashboard
    __debug { "HOME #{__method__} | params = #{params.inspect}" }
    @item, @pref = fetch_my_account
  end

end

__loading_end(__FILE__)
