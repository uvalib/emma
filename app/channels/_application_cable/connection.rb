# app/channels/_application_cable/connection.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApplicationCable::Connection
#
# @!attribute [rw] current_user
#   The authenticated user defined in #identified_by and set in #connect.
#   @return [User, nil]
#
class ApplicationCable::Connection < ActionCable::Connection::Base

  include ApplicationCable::Common

  # ===========================================================================
  # :section: ActionCable
  # ===========================================================================

  identified_by :current_user

  rescue_from StandardError, with: :report_error

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The method called when the WebSocket connection is opened.
  #
  # @return [void]
  #
  def connect
    __debug_cable(__method__)
    self.current_user = get_verified_user
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Return the Devise-authenticated user.
  #
  # @raise [ActionCable::Connection::Authorization::UnauthorizedError]
  #
  # @return [User]
  #
  def get_verified_user
    env['warden'].user or reject_unauthorized_connection
  end

  # report_error
  #
  # @param [Exception] e
  #
  # @return [void]
  #
  def report_error(e)
    Log.error("#{self.class}", e)
  end

end

__loading_end(__FILE__)
