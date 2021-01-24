# app/services/bookshare_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'bs'

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

  include Bs

  # Include send/receive modules from "app/services/bookshare_service/**.rb".
  include_submodules(self)

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    # @!method instance
    #   @return [BookshareService]
    # @!method update
    #   @return [BookshareService]
    class << self
    end
  end
  # :nocov:

end

__loading_end(__FILE__)
