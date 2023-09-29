# app/helpers/auth_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for working with authentication strategies.
#
module AuthHelper

  include Emma::Common

  extend self

  # ===========================================================================
  # :section: OmniAuth::Strategy methods
  # ===========================================================================

  public

  # Generate the authentication data to be associated with the given user.
  #
  # @param [User, nil] user
  #
  # @return [OmniAuth::AuthHash, nil]
  #
  def auth_hash(user)
    return unless user.is_a?(User)
    OmniAuth::AuthHash.new.tap do |auth|
      auth.provider         = user.provider
      auth.uid              = user.account
      auth.info!.first_name = user.first_name
      auth.info!.last_name  = user.last_name
      auth.info!.email      = user.email
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
