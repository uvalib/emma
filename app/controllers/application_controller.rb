# app/controllers/application_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

# ApplicationController
#
class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception

  add_flash_types :error, :success

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # TODO: ???

end
