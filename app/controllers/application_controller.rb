# app/controllers/application_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApplicationController
#
class ApplicationController < ActionController::Base

  include MetricsConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Handled individually by each controller subclass.

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  check_authorization unless: :devise_controller?

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protect_from_forgery with: :exception

  # ===========================================================================
  # :section: Session management
  # ===========================================================================

  # Handled individually by each controller subclass including SessionConcern.

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    __debug_exception('RESCUE_FROM', exception)
    flash[:alert] ||= 'Your session has expired' # TODO: I18n
    redirect_to root_path
  end

  # ===========================================================================
  # :section: Helpers
  # ===========================================================================

  add_flash_types :error, :success # TODO: keep?

  helper_method :modal?
  helper_method :layout

  # ===========================================================================
  # :section: Helpers
  # ===========================================================================

  protected

  # Indicate whether rendering within a modal dialog (<iframe>).
  #
  def modal?
    @modal ||= true?(params[:modal])
  end

  # The current layout template.
  #
  # @return [String]
  # @return [FalseClass]              If `request.xhr?`
  #
  def layout
    if request.xhr?
      false
    elsif modal?
      'modal'
    else
      'application'
    end
  end

end

__loading_end(__FILE__)
