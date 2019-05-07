# app/controllers/auth_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AuthController
#
class AuthController < ApplicationController

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == POST /auth/callback
  # Receives the OAuth2 callback from Bookshare.
  #
  # @see https://apidocs-qa.bookshare.org/auth/index.html#sample-authorization-code-flow
  # @see https://apidocs-qa.bookshare.org/auth/index.html#sample-implicit-flow
  #
  def callback
    options = params.to_unsafe_h.symbolize_keys
    __debug { "*** #{__method__} | options = #{options.inspect} | fragment = #{URI.parse(request.original_url).fragment.inspect}" }
    if options[:code].present?
      ApiService.instance(options)    # Authorization code grant flow.
    elsif (data = URI.parse(request.original_url).fragment).present?
      ApiService.instance(data)       # Implicit grant flow.
    end
    render json: {}, status: :ok
  end

  # == POST /auth/oauth2
  # Receives the OAuth2 callback from Bookshare.
  #
  def oauth2
    __debug "AuthController.#{__method__} ??? | params #{params.inspect}"
=begin
    authentication_action
=end
  end

  def passthru
    __debug "AuthController.#{__method__} ??? | params #{params.inspect}"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

=begin
  # TODO: This is an implementation based on multiple providers.
  # It may be overkill.
  #
  # @param [?] auth
  #
  # @return [void]
  #
  def authentication_action(auth = request.env['omniauth.auth'])
    user = User.from_omniauth(auth)
    if user.persisted?
      session[:user_id] = user.id
      sign_in_and_redirect user, notice: "Signed in as #{user}"
    else
      # Devise allows us to save the attributes even though  we haven't created
      # the user account yet.
      session['devise.user_attributes'] = user.attributes
      # Because Twitter doesn't provide user's email, it would be nice if we
      # force user to enter it manually on the registration page before we
      # create their account. Here we pass the callback parameter so that we
      # could use it to edit the registration page.
      redirect_to new_user_registration_url(callback: 'twitter')
    end
  end
=end

end

__loading_end(__FILE__)
