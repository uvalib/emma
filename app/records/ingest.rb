# app/records/ingest.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects serialized to the EMMA Unified Ingest API.
#
# @see https://app.swaggerhub.com/apis/bus/emma-federated-ingestion-api/0.0.5          HTML API documentation
# @see https://api.swaggerhub.com/apis/bus/emma-federated-ingestion-api/0.0.5          JSON API specification
# @see https://app.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5   HTML schema documentation
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5   JSON schema specification
#
module Ingest
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

module Ingest
  include Ingest::Api::Common
end

__loading_end(__FILE__)
