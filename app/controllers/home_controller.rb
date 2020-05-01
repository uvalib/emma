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

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include SerializationConcern

  # Non-functional hints for RubyMine.
  # :nocov:
  include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!, only: %i[dashboard]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # None

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /home
  # The main application page.
  #
  # == Implementation Notes
  # There is no app/views/home/main.html.erb; this method renders the user
  # dashboard for an authenticated session or the welcome screen otherwise.
  #
  def main
    __debug_route
    if current_user
      redirect_to dashboard_path
    else
      redirect_to welcome_path
    end
  end

  # == GET /home/welcome
  # The main application page for anonymous users.
  #
  def welcome
    __debug_route
  end

  # == GET /home/dashboard
  # The main application page for authenticated users.
  #
  def dashboard
    __debug_route
    @item, @preferences, @history = get_account_details
    response.status =
      case flash.now[:alert]
        when '', nil             then 200 # OK
        when /already signed in/ then 403 # Forbidden
        else                          401 # Unauthorized
      end
    respond_to do |format|
      format.html { render layout: layout }
      format.json { render_json show_values(as: :hash)  }
      format.xml  { render_xml  show_values(as: :array) }
    end
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @overload show_values(as: :array)
  #   @return [Hash{Symbol=>Array}]
  #
  # @overload show_values(as: :hash)
  #   @return [Hash{Symbol=>Hash}]
  #
  # @overload show_values
  #   @return [Hash{Symbol=>Hash}]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  # noinspection RubyYardReturnMatch
  def show_values(as: nil)
    result = { details: @item, preferences: @preferences, history: @history }
    { account: super(result, as: as) }
  end

end

__loading_end(__FILE__)
