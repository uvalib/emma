# app/services/search_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Receive messages through the EMMA Federated Search API.
#
# == Authentication and authorization
# Bookshare uses OAuth2, which is handled in this application by Devise and
# OmniAuth.
#
# @see lib/emma/config.rb
# @see config/initializers/devise.rb
#
class SearchService < ApiService

  include Search

  # Include send and receive modules from "app/services/search_service/*.rb".
  #
  # noinspection RubyYardParamTypeMatch
  if in_debugger?
    include_submodules(self, __FILE__)
  else
    include_submodules(self)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The URL for the API connection.
  #
  # @return [String]
  #
  # This method overrides:
  # @see ApiService#base_url
  #
  def base_url
    @base_url ||= BASE_URL
  end

end

__loading_end(__FILE__)
