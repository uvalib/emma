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
    if BS_AUTH
      # noinspection RubyMismatchedArgumentType
      OmniAuth::Strategies::Bookshare.auth_hash(user)
    else
      OmniAuth::AuthHash.new.tap do |auth|
        auth.provider         = user.provider
        auth.uid              = user.account
        auth.info!.first_name = user.first_name
        auth.info!.last_name  = user.last_name
        auth.info!.email      = user.email
      end
    end
  end

  # auth_default_options                                                        # if BS_AUTH
  #
  # @return [OmniAuth::Strategy::Options]
  #
  def auth_default_options
    OmniAuth::Strategies::Bookshare.default_options
  end
    .tap { |meth| disallow(meth) unless BS_AUTH }

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
