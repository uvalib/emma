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
  include UserConcern
  include ParamsConcern
  include SessionConcern
  include SerializationConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Not applicable.

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
    __debug { "HOME #{__method__} | params = #{params.inspect}" }
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
    __debug { "HOME #{__method__} | params = #{params.inspect}" }
  end

  # == GET /home/dashboard
  # The main application page for authenticated users.
  #
  def dashboard
    __debug { "HOME #{__method__} | params = #{params.inspect}" }
    @item, @preferences, @history = get_account_details
    response.status =
      case flash.now[:alert]
        when '', nil             then 200 # OK
        when /already signed in/ then 403 # Forbidden
        else                          401 # Unauthorized
      end
    respond_to do |format|
      format.html
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
  # @param [ApiMyAccountSummary, nil]     item
  # @param [ApiMyAccountPreferences, nil] pref
  # @param [ApiTitleDownloadList, nil]    hist
  # @param [Symbol]                       as
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @item, pref = @preferences, hist = @history, as: nil)
    { account: super(details: item, preferences: pref, history: hist, as: as) }
  end

end

__loading_end(__FILE__)
