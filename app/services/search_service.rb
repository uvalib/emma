# app/services/search_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'search'

# Receive messages through the EMMA Unified Search API.
#
class SearchService < ApiService

  include Search

  # Include send/receive modules from "app/services/search_service/**.rb".
  include_submodules(self)

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    # @!method instance
    #   @return [SearchService]
    # @!method update
    #   @return [SearchService]
    class << self
    end
  end
  # :nocov:

end

__loading_end(__FILE__)
