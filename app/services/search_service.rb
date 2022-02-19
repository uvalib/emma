# app/services/search_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Receive messages through the EMMA Unified Search API.
#
class SearchService < ApiService

  DESTRUCTIVE_TESTING = false

  #include Search # NOTE: commented-out

  # Include send/receive modules from "app/services/search_service/**.rb".
  include_submodules(self)

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
