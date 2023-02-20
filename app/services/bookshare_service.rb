# app/services/bookshare_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Send/receive messages through the Bookshare API.
#
# == Authentication and authorization
# Bookshare uses OAuth2, which is handled in this application by Devise and
# OmniAuth.
#
# @see file:lib/emma/config.rb
# @see file:config/initializers/devise.rb
#
class BookshareService < ApiService

  DESTRUCTIVE_TESTING = false

  include Bs

  include BookshareService::Properties
  include BookshareService::Action
  include BookshareService::Common
  include BookshareService::Definition
  include BookshareService::Identity
  include BookshareService::Status
  include BookshareService::Testing

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # @!method instance
    #   @return [BookshareService]
    # @!method update
    #   @return [BookshareService]
    class << self
    end

    # :nocov:
  end

end

__loading_end(__FILE__)
