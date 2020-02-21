# app/records/search.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects de-serialized from the EMMA Unified Search API.
module Search
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

require 'search/api/common'

module Search
  include Search::Api::Common
end

__loading_end(__FILE__)
