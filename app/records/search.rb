# app/records/search.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects de-serialized from the EMMA Unified Search API.
#
# @see https://api.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.3           JSON API specification
# @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.3           HTML API documentation
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3 JSON schema specification
# @see https://app.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3 HTML schema documentation
#
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
