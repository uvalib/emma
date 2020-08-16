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

end

__loading_end(__FILE__)
