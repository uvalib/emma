# app/services/search_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Transmit messages through the EMMA Unified Search API.
#
class SearchService < ApiService

  DESTRUCTIVE_TESTING = false

  include Search

  include SearchService::Properties
  include SearchService::Action
  include SearchService::Common
  include SearchService::Definition
  include SearchService::Status
  include SearchService::Testing

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # @!method instance
    #   @return [SearchService]
    # @!method update
    #   @return [SearchService]
    class << self
    end

    # :nocov:
  end

end

__loading_end(__FILE__)
