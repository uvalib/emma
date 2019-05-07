# app/controllers/auth_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AuthController # TODO: delete class
#
class AuthController < ApplicationController

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin
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
=end

end

__loading_end(__FILE__)
