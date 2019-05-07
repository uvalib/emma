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

  # Display the User instance as the email address.
  #
  # @return [String]
  #
  def to_s
    email
  end

=begin
  def self.from_omniauth(auth, signed_in_resource = nil)
    # Check whether there is already a user.
    user = User.where(provider: auth.provider, uid: auth.uid).first
    return user if user.present?

    # Check whether there is already a user with the same email address.
    user = User.find_by_email(auth.info.email)
    return user if user.present?

    # Create a new user.
    user = User.new
    case auth.provider

      when 'oauth2' # TODO: ????
        user.provider        = auth.provider
        user.uid             = auth.uid
        user.oauth_token     = auth.credentials.token
        user.first_name      = auth.info.first_name
        user.last_name       = auth.info.last_name
        user.email           = auth.info.email

      when 'google_oauth2'
        user.provider        = auth.provider
        user.uid             = auth.uid
        user.oauth_token     = auth.credentials.token
        user.first_name      = auth.info.first_name
        user.last_name       = auth.info.last_name
        user.email           = auth.info.email

        # Google's token doesn't last forever:
        user.oauth_expires_at = Time.at(auth.credentials.expires_at)

      when 'facebook'
        user.provider        = auth.provider
        user.uid             = auth.uid
        user.oauth_token     = auth.credentials.token
        user.first_name      = auth.extra.raw_info.first_name
        user.last_name       = auth.extra.raw_info.last_name
        user.email           = auth.extra.raw_info.email

        # Facebook's token doesn't last forever:
        user.oauth_expires_at = Time.at(auth.credentials.expires_at)

      when 'linkedin'
        user.provider        = auth.provider
        user.uid             = auth.uid
        user.oauth_token     = auth.credentials&.token
        user.first_name      = auth.info&.first_name
        user.last_name       = auth.info&.last_name
        user.email           = auth.info&.email

      when 'twitter'
        user.provider        = auth.provider
        user.uid             = auth.uid
        user.oauth_token     = auth.credentials.token
        user.oauth_user_name = auth.extra.raw_info.name

      when 'github'
        user.provider        = auth['provider']
        user.uid             = auth['uid']
        user.oauth_user_name = auth.dig('info', 'name')
        user.email           = auth.dig('info', 'email')

    end
    user.save
  end

  # For Twitter (save the session even though we redirect user to registration
  # page first)
  def self.new_with_session(params, session)
    if (attributes = session['devise.user_attributes'])
      new(attributes, without_protection: true) do |user|
        user.attributes = params
        user.valid?
      end
    else
      super
    end
  end

  # For Twitter (disable password validation)
  def password_required?
    super && provider.blank?
  end
=end

end

__loading_end(__FILE__)
