# app/services/bookshare_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Common
#
module BookshareService::Common

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  # @private
  #
  def self.included(base)
    base.send(:include, BookshareService::Definition)
  end

  include ApiService::Common

  include BookshareService::Properties


  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  public

  # Extract the user name to be used for API parameters.
  #
  # @param [User, String, nil] user
  #
  # @return [String]
  #
  def name_of(user)
    name = user.is_a?(Hash) ? user['uid'] : user
    name.to_s.presence || DEFAULT_USER
  end

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  protected

  # Set the user for the current session.
  #
  # @param [User, nil] u
  #
  # @raise [RuntimeError]             If *u* is invalid.
  #
  # @return [void]
  #
  def set_user(u)
    super
    @user = @user&.bookshare_user
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Add service-specific API options.
  #
  # @param [Hash, nil] params         Default: @params.
  #
  # @return [Hash]                    New API parameters.
  #
  def api_options(params = nil)
    super.tap do |result|
      result[:limit] = MAX_LIMIT if result[:limit].to_s == 'max'
    end
  end

end

__loading_end(__FILE__)
