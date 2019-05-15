# app/models/api_user_subscription_type_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class User < ApplicationRecord

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :omniauthable,
         omniauth_providers: User::OmniauthCallbacksController::PROVIDERS

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Display the User instance as the user identifier.
  #
  # @return [String]
  #
  def to_s
    uid
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The user ID is the same as the Bookshare ID, which is the same as the email
  # address.
  #
  # @return [String]
  #
  def uid
    email
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Get (or create) a database entry for the indicated user and update the
  # associated User object with additional information from the provider.
  #
  # @param [Hash, OmniAuth::AuthHash] auth
  #
  # @return [User]
  #
  # @see https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
  #
  def self.from_omniauth(auth)
    return unless auth.is_a?(Hash)
    auth = OmniAuth::AuthHash.new(auth)
    find_or_create_by(email: auth.uid).tap do |user|
      # user.email       = auth.info.email
      user.first_name    = auth.info.first_name
      user.last_name     = auth.info.last_name
      user.access_token  = auth.credentials.token
      user.refresh_token = auth.credentials.refresh_token
    end
  end

end

__loading_end(__FILE__)
